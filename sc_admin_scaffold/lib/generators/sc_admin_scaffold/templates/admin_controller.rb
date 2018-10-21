class Admin::<%= controller_class_name %>Controller < ApplicationController
  before_action :set_<%= singular_name %>, only: [:show, :edit, :update, :destroy]
  before_action :authenticate_admin_user!

  def index
    @<%= plural_name %> = <%= singular_name.capitalize %>.all
  end
<% if show_action? -%>

  def show
  end
<% end -%>

  def new
    @<%= singular_name %> = <%= singular_name.capitalize %>.new
  end

  def create
    # user assosiation must be made.
    @<%= singular_name %> = current_admin_user.<%= plural_name %>.new(<%= singular_name %>_params)

    if @<%= singular_name %>.save
      redirect_to admin_<%= plural_name %>_url, notice: '<%= class_name.underscore.humanize %> was successfully created.'
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @<%= singular_name %>.update(<%= singular_name %>_params)
      redirect_to admin_<%= plural_name %>_url, notice: '<%= class_name.underscore.humanize %> was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @<%= singular_name %>.destroy
    redirect_to admin_<%= plural_name %>_url, notice: '<%= class_name.underscore.humanize %> was successfully destroyed.'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_<%= singular_name %>
      @<%= singular_name %> = <%= singular_name.capitalize %>.find(params[:id])
    end

  def <%= singular_name %>_params
    params.require(:<%= singular_name %>).permit(<%= editable_attributes.map { |a| a.name.dup.prepend(':') }.join(', ') %>)
  end
end
