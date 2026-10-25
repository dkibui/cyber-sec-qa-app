class ProjectsController < ApplicationController
  def index
    @projects = Project.includes(:architect, :developer).order(:name)
  end

  def show
    @project = Project.find(params[:id])
    @assessments = @project.assessments.includes(:tester).order(:created_at)
  end

  def new
    require_permission! Current.user.can_create_project?
    @project = Project.new
  end

  def create
    require_permission! Current.user.can_create_project?
    @project = Project.new(params.expect(project: [ :name, :architect_id, :developer_id ]))
    if @project.save
      redirect_to @project, notice: "Project created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def submit
    @project = Project.find(params[:id])
    require_permission! Current.user.can_submit?(@project)
    assessment = @project.submit!
    redirect_to assessment, notice: "Submitted. A security check has started."
  rescue Project::InvalidTransition => e
    redirect_to @project, alert: e.message
  end
end
