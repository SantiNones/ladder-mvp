namespace :narrative do
  desc "Generate and persist narrative + prompt_payload for Ana's seeded snapshots"
  task generate: :environment do
    ana = Person.find_by!(name: "Ana Ferrer")
    snapshots = ana.snapshots.order(:closed_at)

    if snapshots.empty?
      abort "No snapshots found for Ana Ferrer. Run bin/rails db:seed first."
    end

    snapshots.each do |snapshot|
      visible = VisibilityResolver.call(
        viewer: ana,
        subject: ana,
        snapshot: snapshot
      )
      if visible[:access] == :denied
        warn "Skipping #{snapshot.cycle_label}: visibility denied"
        next
      end

      prompt_payload = PromptPayloadBuilder.call(visible: visible)
      narrative = NarrativeGenerator.call(prompt_payload: prompt_payload)

      snapshot.update!(
        prompt_payload: prompt_payload,
        narrative: narrative.to_json
      )

      puts "Persisted narrative for Ana / #{snapshot.cycle_label} (snapshot ##{snapshot.id})"
    end
  end
end
