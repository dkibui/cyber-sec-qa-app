class ControlImportsController < ApplicationController
  MAX_BYTES = 1.megabyte

  before_action { require_permission! Current.user.can_manage_library? }

  def new
  end

  def preview
    file = params[:file]
    return redirect_to(new_control_import_path, alert: "Choose a CSV file first.") if file.blank?
    return redirect_to(new_control_import_path, alert: "That file is too large to be a control library.") if file.size > MAX_BYTES

    @csv = file.read.force_encoding("UTF-8").delete_prefix("\uFEFF").scrub
    @plan = ControlLibraryImport.new(@csv)
  end

  def confirm
    csv = params[:csv].to_s
    return redirect_to(new_control_import_path, alert: "That file is too large.") if csv.bytesize > MAX_BYTES

    plan = ControlLibraryImport.new(csv)
    return redirect_to(new_control_import_path, alert: "Nothing could be imported from that file.") unless plan.importable?

    domains = plan.new_domains
    created = plan.commit!
    redirect_to domains_path, notice: "Imported #{created} controls (#{domains} new domains)."
  end
end
