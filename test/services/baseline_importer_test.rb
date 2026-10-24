require "test_helper"

class BaselineImporterTest < ActiveSupport::TestCase
  CSV_PATH = Rails.root.join("db/seed_data/API_Baseline_Security_Report.csv")

  test "parse reads every control and repairs the duplicate refs" do
    entries = BaselineImporter.parse(CSV_PATH)
    assert_equal 60, entries.size
    refs = entries.map { |e| "#{e.domain_number}.#{e.sequence}" }
    assert_equal refs.uniq, refs
  end

  test "imports the library with permanent numbering and no gap" do
    BaselineImporter.import_library!(CSV_PATH)
    assert_equal 8, Domain.count
    assert_equal 60, Control.count
    assert_equal 8, Domain.find_by!(name: "API Inventory").number
    assert_equal "1.10", Domain.find_by!(number: 1).controls.last.ref
    assert_equal "5.10", Domain.find_by!(number: 5).controls.last.ref
    assert_equal "6.10", Domain.find_by!(number: 6).controls.last.ref
  end

  test "import is idempotent" do
    2.times { BaselineImporter.import_library!(CSV_PATH) }
    assert_equal 60, Control.count
    assert_equal 8, Domain.count
  end
end