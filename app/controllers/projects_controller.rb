class ProjectsController < ApplicationController
  def index
    @projects = Project.includes(:architect, :developer).order(:name)
  end

  def show
    @project = Project.find(params[:id])
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
end