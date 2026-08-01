# Deterministic gap computation. No HTTP, no session, no LLM.
# See SPEC.md §5.
class GapCalculator
  def self.call(person:, window_start:, window_end:)
    new(person: person, window_start: window_start, window_end: window_end).call
  end

  def initialize(person:, window_start:, window_end:)
    @person = person
    @window_start = window_start
    @window_end = window_end
  end

  def call
    target_level = @person.level_position + 1
    target_criteria = Criterion.where(level_position: target_level).order(:code)

    if target_criteria.empty?
      return {
        met: [],
        gap: [],
        at_top_of_framework: true
      }
    end

    met = []
    gap = []

    target_criteria.each do |criterion|
      relevant = Evidence
        .where(person_id: @person.id, criterion_id: criterion.id)
        .where(occurred_on: @window_start..@window_end)
        .order(:id)

      corroborating = relevant.where.not(author_relation: "self")

      if corroborating.exists?
        met << {
          "criterion_id" => criterion.id,
          "evidence_ids" => corroborating.pluck(:id)
        }
      elsif relevant.exists?
        gap << {
          "criterion_id" => criterion.id,
          "state" => "uncorroborated",
          "evidence_ids" => relevant.pluck(:id)
        }
      else
        gap << {
          "criterion_id" => criterion.id,
          "state" => "empty",
          "evidence_ids" => []
        }
      end
    end

    {
      met: met,
      gap: gap,
      at_top_of_framework: false
    }
  end
end
