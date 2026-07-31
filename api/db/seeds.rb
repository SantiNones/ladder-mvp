# Idempotent seed matching SPEC.md §12.
# Snapshot met/gap JSON is hand-authored here; GapCalculator arrives in S1.

CRITERIA = [
  { code: "RES-2.1", level_position: 2, competency: "RES",
    text: "I follow through on my commitments, take responsibility for my work, and deliver on time" },
  { code: "DIR-2.1", level_position: 2, competency: "DIR",
    text: "I have a growth mindset and am comfortable experimenting with new approaches, learning, owning the outcomes, and sharing what I learned" },
  { code: "TAL-2.1", level_position: 2, competency: "TAL",
    text: "I help more junior members of my team, interns, or new hires taking into account their unique strengths, backgrounds, and working styles" },
  { code: "CUL-2.1", level_position: 2, competency: "CUL",
    text: "I write and speak with clarity and focus" },
  { code: "CRA-2.1", level_position: 2, competency: "CRA",
    text: "I translate ideas into clear code, written to be read as well as executed" },
  { code: "RES-3.1", level_position: 3, competency: "RES",
    text: "I deliver some of my team's goals on time and with a high standard of quality" },
  { code: "RES-3.2", level_position: 3, competency: "RES",
    text: "When I encounter barriers, I unblock myself and my team by proactively assessing and eliminating the root cause" },
  { code: "DIR-3.1", level_position: 3, competency: "DIR",
    text: "I navigate ambiguity by focusing on the greater purpose, goals, and desired impact to move forward one step at a time" },
  { code: "DIR-3.2", level_position: 3, competency: "DIR",
    text: "I work collaboratively with my manager to set realistic and ambitious short-term goals to deliver customer value quickly and break these goals down into smaller projects for my team or myself" },
  { code: "TAL-3.1", level_position: 3, competency: "TAL",
    text: "I actively look for opportunities to mentor new hires, interns and apprentices" },
  { code: "TAL-3.2", level_position: 3, competency: "TAL",
    text: "I solicit and offer honest and constructive feedback that is delivered with empathy to help others learn and grow" },
  { code: "CUL-3.1", level_position: 3, competency: "CUL",
    text: "I build relationships across teams and help get to positive outcomes" },
  { code: "CUL-3.2", level_position: 3, competency: "CUL",
    text: "I tailor my message to my audience, presenting it clearly and concisely at the right altitude" },
  { code: "CRA-3.1", level_position: 3, competency: "CRA",
    text: "I ensure high code quality in code reviews. I adopt approaches (e.g., set up best practices and coding standards, help resolve differences of opinions) to foster an effective/collaborative code review culture." },
  { code: "CRA-3.2", level_position: 3, competency: "CRA",
    text: "I am able to independently design software components in well scoped scenarios, with simplicity and maintenance as key considerations. My components are testable, debuggable and have logical APIs that are not easily misused." }
].freeze

CRITERIA.each do |attrs|
  Criterion.find_or_create_by!(code: attrs[:code]) do |c|
    c.level_position = attrs[:level_position]
    c.competency = attrs[:competency]
    c.text = attrs[:text]
    c.source = "dropbox-public"
  end
end

laura = Person.find_or_create_by!(name: "Laura Puig") do |p|
  p.role = "manager"
  p.level_position = 3
  p.manager = nil
end
laura.update!(role: "manager", level_position: 3, manager: nil)

ana = Person.find_or_create_by!(name: "Ana Ferrer") do |p|
  p.role = "employee"
  p.level_position = 2
  p.manager = laura
end
ana.update!(role: "employee", level_position: 2, manager: laura)

carlos = Person.find_or_create_by!(name: "Carlos Medina") do |p|
  p.role = "employee"
  p.level_position = 2
  p.manager = laura
end
carlos.update!(role: "employee", level_position: 2, manager: laura)

diego = Person.find_or_create_by!(name: "Diego Rams") do |p|
  p.role = "employee"
  p.level_position = 2
  p.manager = nil
end
diego.update!(role: "employee", level_position: 2, manager: nil)

marta = Person.find_or_create_by!(name: "Marta Solé") do |p|
  p.role = "hr"
  p.level_position = 3
  p.manager = nil
end
marta.update!(role: "hr", level_position: 3, manager: nil)

by_code = Criterion.all.index_by(&:code)

def upsert_evidence!(person:, criterion:, author:, author_relation:, source_type:, body:, occurred_on:)
  evidence = Evidence.find_or_initialize_by(
    person: person,
    criterion: criterion,
    author: author,
    occurred_on: occurred_on
  )
  evidence.assign_attributes(
    author_relation: author_relation,
    source_type: source_type,
    body: body
  )
  evidence.save!
  evidence
end

# --- H2 2025 (2 criteria covered for Ana) ---
h2_start = Date.new(2025, 7, 1)
h2_end = Date.new(2025, 12, 31)

h2_res = upsert_evidence!(
  person: ana, criterion: by_code["RES-3.1"], author: laura,
  author_relation: "manager", source_type: "manager_note",
  body: "Ana delivered the billing export milestone on schedule with clean handoff notes.",
  occurred_on: Date.new(2025, 9, 15)
)
h2_cra = upsert_evidence!(
  person: ana, criterion: by_code["CRA-3.1"], author: carlos,
  author_relation: "peer", source_type: "peer_feedback",
  body: "Ana's reviews catch API edge cases early and keep the team's bar consistent.",
  occurred_on: Date.new(2025, 10, 20)
)

h2_met = [
  { "criterion_id" => by_code["RES-3.1"].id, "evidence_ids" => [h2_res.id] },
  { "criterion_id" => by_code["CRA-3.1"].id, "evidence_ids" => [h2_cra.id] }
]
h2_gap = %w[RES-3.2 DIR-3.1 DIR-3.2 TAL-3.1 TAL-3.2 CUL-3.1 CUL-3.2 CRA-3.2].map do |code|
  { "criterion_id" => by_code[code].id, "state" => "empty", "evidence_ids" => [] }
end

h2 = Snapshot.find_or_initialize_by(person: ana, cycle_label: "H2 2025")
h2.assign_attributes(
  window_start: h2_start,
  window_end: h2_end,
  closed_at: Time.utc(2025, 12, 31, 18, 0, 0),
  level_position_at_close: 2,
  target_level_position: 3,
  met: h2_met,
  gap: h2_gap,
  narrative: nil,
  prompt_payload: nil
)
h2.save!

# --- H1 2026 (5 met + CRA-3.2 uncorroborated; DIR empty) ---
h1_start = Date.new(2026, 1, 1)
h1_end = Date.new(2026, 6, 30)

e_res31 = upsert_evidence!(
  person: ana, criterion: by_code["RES-3.1"], author: laura,
  author_relation: "manager", source_type: "manager_note",
  body: "Ana owned the H1 onboarding flow delivery and hit the quality bar the team set.",
  occurred_on: Date.new(2026, 3, 10)
)
e_res32 = upsert_evidence!(
  person: ana, criterion: by_code["RES-3.2"], author: laura,
  author_relation: "manager", source_type: "project",
  body: "When the payments vendor stalled, Ana traced the root cause and unblocked the squad.",
  occurred_on: Date.new(2026, 4, 2)
)
e_cra31 = upsert_evidence!(
  person: ana, criterion: by_code["CRA-3.1"], author: carlos,
  author_relation: "peer", source_type: "peer_feedback",
  body: "Ana set review norms that shortened debate and raised code quality across the pod.",
  occurred_on: Date.new(2026, 2, 18)
)
e_tal32 = upsert_evidence!(
  person: ana, criterion: by_code["TAL-3.2"], author: laura,
  author_relation: "manager", source_type: "manager_note",
  body: "Ana gave clear, empathetic feedback in 1:1s that helped a teammate close a craft gap.",
  occurred_on: Date.new(2026, 5, 5)
)
e_cul32 = upsert_evidence!(
  person: ana, criterion: by_code["CUL-3.2"], author: marta,
  author_relation: "hr", source_type: "peer_feedback",
  body: "Ana's design review write-ups are concise and pitched at the right altitude for stakeholders.",
  occurred_on: Date.new(2026, 5, 22)
)
e_cra32_self = upsert_evidence!(
  person: ana, criterion: by_code["CRA-3.2"], author: ana,
  author_relation: "self", source_type: "self_claim",
  body: "I designed the notification service components with testable boundaries and simple APIs.",
  occurred_on: Date.new(2026, 4, 28)
)

h1_met = [
  { "criterion_id" => by_code["RES-3.1"].id, "evidence_ids" => [e_res31.id] },
  { "criterion_id" => by_code["RES-3.2"].id, "evidence_ids" => [e_res32.id] },
  { "criterion_id" => by_code["CRA-3.1"].id, "evidence_ids" => [e_cra31.id] },
  { "criterion_id" => by_code["TAL-3.2"].id, "evidence_ids" => [e_tal32.id] },
  { "criterion_id" => by_code["CUL-3.2"].id, "evidence_ids" => [e_cul32.id] }
]
h1_gap = [
  { "criterion_id" => by_code["DIR-3.1"].id, "state" => "empty", "evidence_ids" => [] },
  { "criterion_id" => by_code["DIR-3.2"].id, "state" => "empty", "evidence_ids" => [] },
  { "criterion_id" => by_code["TAL-3.1"].id, "state" => "empty", "evidence_ids" => [] },
  { "criterion_id" => by_code["CUL-3.1"].id, "state" => "empty", "evidence_ids" => [] },
  { "criterion_id" => by_code["CRA-3.2"].id, "state" => "uncorroborated", "evidence_ids" => [e_cra32_self.id] }
]

h1 = Snapshot.find_or_initialize_by(person: ana, cycle_label: "H1 2026")
h1.assign_attributes(
  window_start: h1_start,
  window_end: h1_end,
  closed_at: Time.utc(2026, 6, 30, 18, 0, 0),
  level_position_at_close: 2,
  target_level_position: 3,
  met: h1_met,
  gap: h1_gap,
  narrative: nil,
  prompt_payload: nil
)
h1.save!
