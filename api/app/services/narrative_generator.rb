# Builds a SPEC §7 narrative from an already-filtered prompt_payload.
# Deterministic mode only (D15): template → validate → fallback. No LLM, no HTTP.
class NarrativeGenerator
  ALLOWED_KEYS = %w[summary focus_competency next_steps].freeze
  COMPETENCIES = %w[RES DIR TAL CUL CRA].freeze
  FORBIDDEN_KEYS = %w[
    level level_position readiness score verdict recommendation
    grade rating performance
  ].freeze

  def self.call(prompt_payload:, candidate: nil)
    new(prompt_payload: prompt_payload, candidate: candidate).call
  end

  def initialize(prompt_payload:, candidate: nil)
    @prompt_payload = prompt_payload
    @candidate = candidate
  end

  def call
    result = @candidate.nil? ? build_from_template : deep_stringify(@candidate)
    valid?(result) ? result : fallback
  rescue StandardError
    fallback
  end

  private

  def build_from_template
    gap = Array(@prompt_payload["gap"])
    name = @prompt_payload["subject_first_name"]
    target = @prompt_payload["target_level_name"]
    cycle = @prompt_payload["cycle_label"]
    codes = gap.map { |row| row["code"] }
    focus = dominant_competency(gap)

    summary = if codes.empty?
      "#{name} has no open criteria for #{target} in #{cycle}."
    else
      "#{name}'s gap toward #{target} in #{cycle} covers #{codes.size} " \
        "criteria, with the largest concentration in #{focus}. " \
        "Next steps stay tied to those open codes only."
    end

    {
      "summary" => summary,
      "focus_competency" => focus,
      "next_steps" => codes.map do |code|
        {
          "criterion_code" => code,
          "suggestion" => "Collect corroborating evidence that speaks directly to #{code}."
        }
      end
    }
  end

  def fallback
    codes = gap_codes
    focus = dominant_competency(Array(@prompt_payload["gap"]))
    {
      "summary" => fallback_summary(codes),
      "focus_competency" => focus,
      "next_steps" => codes.map do |code|
        {
          "criterion_code" => code,
          "suggestion" => "Add evidence for #{code}."
        }
      end
    }
  end

  def fallback_summary(codes)
    name = @prompt_payload["subject_first_name"]
    if codes.empty?
      "#{name} has an empty gap for this cycle."
    else
      "#{name} still has open criteria: #{codes.join(', ')}."
    end
  end

  def valid?(result)
    return false unless result.is_a?(Hash)
    keys = result.keys.map(&:to_s)
    return false unless keys.sort == ALLOWED_KEYS.sort
    return false if keys.any? { |k| FORBIDDEN_KEYS.include?(k) }
    return false unless COMPETENCIES.include?(result["focus_competency"].to_s)

    steps = result["next_steps"]
    return false unless steps.is_a?(Array)
    return false unless result["summary"].is_a?(String) && result["summary"].present?

    allowed_codes = gap_codes
    steps.all? do |step|
      step.is_a?(Hash) &&
        allowed_codes.include?(step["criterion_code"].to_s) &&
        step["suggestion"].is_a?(String) &&
        step["suggestion"].present?
    end
  end

  def gap_codes
    Array(@prompt_payload["gap"]).map { |row| row["code"].to_s }
  end

  def dominant_competency(gap)
    counts = gap.each_with_object(Hash.new(0)) { |row, h| h[row["competency"]] += 1 }
    COMPETENCIES.max_by { |c| [counts[c], -COMPETENCIES.index(c)] }
  end

  def deep_stringify(node)
    case node
    when Hash
      node.each_with_object({}) { |(k, v), h| h[k.to_s] = deep_stringify(v) }
    when Array
      node.map { |v| deep_stringify(v) }
    else
      node
    end
  end
end
