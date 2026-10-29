require "csv"

# Reads a baseline CSV and works out what importing it would do, without saving anything.
# Domains and controls are matched to the library by name and description, so importing
# the same file twice adds nothing. Existing records are never changed or deleted.
class ControlLibraryImport
  SEVERITIES = %w[critical high medium low].freeze
  KEEP_UPPER = %w[API OWASP CWE NIST USSD].freeze

  Entry = Struct.new(:ref, :description, :owasp, :cwe_nist, :severity, :existing, keyword_init: true)
  Section = Struct.new(:name, :source_number, :number, :domain, :entries, keyword_init: true)

  attr_reader :sections, :errors, :warnings

  def initialize(text)
    @text = text.to_s
    @sections = []
    @errors = []
    @warnings = []
    @defaulted = 0
    parse
    resolve if errors.empty?
  end

  def new_domains = sections.count { |s| s.domain.nil? }
  def new_controls = sections.sum { |s| s.entries.count { |e| !e.existing } }
  def existing_controls = sections.sum { |s| s.entries.count(&:existing) }
  def importable? = errors.empty? && new_controls.positive?

  # Saves everything or nothing. Returns the number of controls created.
  def commit!
    raise ArgumentError, "This file cannot be imported." unless importable?

    created = 0
    ActiveRecord::Base.transaction do
      sections.each do |section|
        domain = section.domain || Domain.create!(name: section.name)
        section.entries.reject(&:existing).each do |entry|
          domain.controls.create!(description: entry.description, owasp: entry.owasp,
                                  cwe_nist: entry.cwe_nist, default_severity: entry.severity)
          created += 1
        end
      end
    end
    created
  end

  private

  def parse
    rows = CSV.parse(@text, liberal_parsing: true)
    header_index = rows.index { |row| row.any? { |c| c.to_s.match?(/description/i) } }
    if header_index.nil?
      @errors << "No header row found. The file needs a column called \"Control / Test Description\"."
      return
    end

    header = rows[header_index].map { |c| c.to_s.strip }
    @desc_col = header.index { |c| c.match?(/description/i) }
    @owasp_col = header.index { |c| c.match?(/owasp/i) }
    @cwe_col = header.index { |c| c.match?(/cwe|nist/i) }
    @severity_col = header.index { |c| c.match?(/severity/i) }

    rows.each_with_index do |row, index|
      next if index <= header_index
      next if row.all? { |c| c.to_s.strip.empty? }

      first = row[0].to_s.strip
      if (m = first.match(/\A(\d+)\.0\b\s*(.*)\z/m))
        start_section(m[1].to_i, m[2].presence || cell(row, @desc_col), index + 1)
      elsif (m = first.match(/\A(\d+)\.(\d+)\z/))
        add_entry(row, first, m[2].to_i, index + 1)
      elsif first.present?
        @warnings << "Row #{index + 1} was not recognised and was skipped: #{first.truncate(40)}"
      end
    end

    @errors << "No domains or controls were found in the file." if sections.empty?
    if @defaulted.positive?
      @warnings << "#{@defaulted} controls had no usable severity in the file and will default to Medium."
    end
  rescue CSV::MalformedCSVError => e
    @errors << "The file could not be read as CSV: #{e.message}"
  end

  def start_section(source_number, raw_name, row_number)
    name = format_name(raw_name)
    if name.blank?
      @warnings << "Row #{row_number}: a domain heading has no name and was skipped."
      @current = nil
      return
    end

    @current = sections.find { |s| s.name.casecmp?(name) }
    return if @current

    @current = Section.new(name: name, source_number: source_number, entries: [])
    sections << @current
  end

  def add_entry(row, ref_text, source_sequence, row_number)
    if @current.nil?
      @warnings << "Row #{row_number} (#{ref_text}) comes before any domain heading and was skipped."
      return
    end

    description = cell(row, @desc_col).squish
    if description.blank?
      @warnings << "Row #{row_number} (#{ref_text}) has no description and was skipped."
      return
    end

    if @current.entries.any? { |e| norm(e.description) == norm(description) }
      @warnings << "Row #{row_number} (#{ref_text}) repeats an earlier control in this domain and was skipped."
      return
    end

    expected = @current.entries.size + 1
    if source_sequence != expected
      @warnings << "Row #{row_number} says #{ref_text}, but it is control number #{expected} in its domain, " \
        "so it is read as #{@current.source_number}.#{expected}."
    end

    severity = cell(row, @severity_col).downcase
    unless SEVERITIES.include?(severity)
      @defaulted += 1
      severity = "medium"
    end

    @current.entries << Entry.new(description: description, owasp: cell(row, @owasp_col).presence,
                                  cwe_nist: cell(row, @cwe_col).presence, severity: severity, existing: false)
  end

  # Matches the file against the library and works out the refs each control will have.
  def resolve
    next_domain_number = Domain.maximum(:number) || 0

    sections.each do |section|
      domain = Domain.find_by("lower(name) = ?", section.name.downcase)
      known = {}
      next_sequence = 0

      if domain
        section.domain = domain
        section.number = domain.number
        known = domain.controls.index_by { |c| norm(c.description) }
        next_sequence = Control.where(domain_id: domain.id).maximum(:sequence) || 0
      else
        next_domain_number += 1
        section.number = next_domain_number
      end

      if section.source_number != section.number
        @warnings << "The heading #{section.source_number}.0 #{section.name} will be numbered #{section.number} in the library."
      end

      section.entries.each do |entry|
        if (control = known[norm(entry.description)])
          entry.existing = true
          entry.ref = control.ref
        else
          next_sequence += 1
          entry.ref = "#{section.number}.#{next_sequence}"
        end
      end
    end
  end

  def cell(row, column) = column ? row[column].to_s.strip : ""

  def norm(text) = text.to_s.squish.downcase

  def format_name(raw)
    raw.to_s.squish.split(" ").map { |w| KEEP_UPPER.include?(w.upcase) ? w.upcase : w.capitalize }.join(" ")
  end
end