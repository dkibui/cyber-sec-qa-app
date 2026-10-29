class UsersController < ApplicationController
  before_action { require_permission! Current.user.can_manage_users? }
  before_action :set_user, only: %i[edit update]

  def index
    @users = User.order(:email_address)
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      redirect_to users_path, notice: "User #{@user.email_address} created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    attrs = user_params
    attrs.delete(:password) if attrs[:password].blank?

    if @user == Current.user && attrs[:role].present? && attrs[:role] != "admin"
      @user.assign_attributes(attrs.except(:role))
      @user.errors.add(:role, "cannot be changed on your own account, so the app always has an admin")
      return render :edit, status: :unprocessable_entity
    end

    if @user.update(attrs)
      redirect_to users_path, notice: "User #{@user.email_address} updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_user = @user = User.find(params[:id])

  def user_params = params.expect(user: [ :email_address, :role, :password ])
end
