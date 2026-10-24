require "csv"

# Reads the department's baseline checklist CSV into the control library.
#
# The app owns numbering: domains are numbered 1..n in file order (no gap), and controls are
# numbered 1..n within their domain. This also repairs the sample file, where Excel had turned
# "1.10", "5.10" and "6.10" into duplicate "1.1", "5.1" and "6.1".
class BaselineImporter
  SECTION_NAMES = {
    1 => "Authentication", 2 => "Authorization", 3 => "Data Exposure", 4 => "Rate Limiting",
    5 => "Secure Configuration", 6 => "Input Validation", 7 => "Auditing & Logging", 9 => "API Inventory"
  }.freeze

  STATUSES = {
    "passed" => :passed, "failed" => :failed, "partial" => :partial,
    "pending" => :pending, "n/a" => :not_applicable
  }.freeze

  Entry = Struct.new(:domain_name, :domain_number, :sequence, :description, :owasp, :cwe_nist,
                     :status, :severity, :owner, keyword_init: true)

  # Turns the file into plain Entry structs. Writes nothing to the database.
  def self.parse(path)
    entries = []
    sequence = 0
    domain_number = 0
    domain_name = nil

    CSV.foreach(path, encoding: "bom|utf-8") do |row|
      first = row[0].to_s.strip
      if (section = first.match(/\A(\d+)\.0\s/))
        domain_name = SECTION_NAMES.fetch(section[1].to_i) { raise ArgumentError, "Unknown section #{section[1]}" }
        domain_number += 1
        sequence = 0
      elsif domain_name && first.match?(/\A\d+\.\d+\z/)
        sequence += 1
        entries << Entry.new(
          domain_name: domain_name, domain_number: domain_number, sequence: sequence,
          description: row[1].to_s.strip, owasp: row[2].to_s.strip, cwe_nist: row[3].to_s.strip,
          status: STATUSES.fetch(row[4].to_s.strip.downcase) { raise ArgumentError, "Unknown status #{row[4].inspect}" },
          severity: row[5].to_s.strip.downcase.to_sym, owner: row[7].to_s.strip.presence
        )
      end
    end
    entries
  end

  # Idempotent: safe to run again. Everything happens in one transaction.
  def self.import_library!(path)
    ApplicationRecord.transaction do
      parse(path).each do |e|
        domain = Domain.find_or_create_by!(name: e.domain_name) { |d| d.number = e.domain_number }
        control = domain.controls.find_or_initialize_by(sequence: e.sequence)
        control.update!(description: e.description, owasp: e.owasp, cwe_nist: e.cwe_nist, default_severity: e.severity)
      end
    end
  end
end