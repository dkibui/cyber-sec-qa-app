class ControlsController < ApplicationController
  before_action { require_permission! Current.user.can_manage_library? }

  def new
    @control = Domain.find(params[:domain_id]).controls.build
  end

  def create
    @control = Domain.find(params[:domain_id]).controls.build(control_params)
    if @control.save
      redirect_to domains_path, notice: "Control #{@control.ref} added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @control = Control.find(params[:id])
  end

  def update
    @control = Control.find(params[:id])
    if @control.update(control_params)
      redirect_to domains_path, notice: "Control #{@control.ref} updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def retire
    control = Control.find(params[:id])
    control.retire!
    redirect_to domains_path, notice: "Control #{control.ref} retired. Its number will not be reused."
  end

  def restore
    control = Control.find(params[:id])
    control.restore!
    redirect_to domains_path, notice: "Control #{control.ref} restored."
  end

  private

  def control_params
    params.expect(control: [ :description, :owasp, :cwe_nist, :default_severity ])
  end
end
