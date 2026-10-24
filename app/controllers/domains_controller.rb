class DomainsController < ApplicationController
  def index
    @domains = Domain.ordered.includes(:controls)
  end

  def new
    require_permission! Current.user.can_manage_library?
    @domain = Domain.new
  end

  def create
    require_permission! Current.user.can_manage_library?
    @domain = Domain.new(params.expect(domain: [ :name ]))
    if @domain.save
      redirect_to domains_path, notice: "Domain added as number #{@domain.number}."
    else
      render :new, status: :unprocessable_entity
    end
  end
end
