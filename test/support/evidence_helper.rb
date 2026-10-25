module EvidenceHelper
  # A real 1x1 PNG, so Active Storage identifies it as an image.
  PNG = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==".unpack1("m")

  # Logs a finding with one screenshot against a control result.
  def add_evidence(result)
    finding = result.assessment.findings.create!(control_result: result, category: "Test", test_objective: "x", observations: "y")
    evidence = finding.evidences.build(caption: "Figure 1")
    evidence.file.attach(io: StringIO.new(PNG), filename: "shot.png", content_type: "image/png")
    evidence.save!
    finding
  end
end
