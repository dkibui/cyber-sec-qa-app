namespace :baseline do
  desc "Import the control library from a baseline CSV: bin/rails baseline:import[path]"
  task :import, [ :path ] => :environment do |_, args|
    path = args[:path] || Rails.root.join("db/seed_data/API_Baseline_Security_Report.csv")
    BaselineImporter.import_library!(path)
    puts "Library now has #{Domain.count} domains and #{Control.count} controls."
  end
end