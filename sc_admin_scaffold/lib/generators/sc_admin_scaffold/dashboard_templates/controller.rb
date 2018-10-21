class Admin::<%= singular_name.capitalize %>Controller < ApplicationController
  before_action :authenticate_admin_user!

  def index
    @user = current_admin_user
  end
end
