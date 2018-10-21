class <%= controller_class_name %>Controller < ApplicationController

  def index
    @<%= plural_name %> = <%= singular_name.capitalize %>.all
  end

  def show
    @<%= singular_name %> = <%= singular_name.capitalize %>.find(params[:id])
  end

end
