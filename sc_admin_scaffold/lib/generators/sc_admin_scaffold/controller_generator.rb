require 'generators/sc_admin_scaffold/generator_helpers'

module ScAdminScaffold
  module Generators
    # Custom scaffold generator
    class ControllerGenerator < Rails::Generators::NamedBase
      include Rails::Generators::ResourceHelpers
      include ScAdminScaffold::Generators::GeneratorHelpers

      source_root File.expand_path('../templates', __FILE__)

      desc "Generates controller, controller_spec and views for the model with the given NAME."

      #class_option :skip_show, type: :boolean, default: false, desc: "Skip \"show\" action"
      #class_option :admin, :type => :boolean, :default => false, :description => "generate an admin specific controller and views"
      class_option :user, :type => :boolean, :default => false, :description => "generate an user specific controller and views"
      class_option :admin, :type => :boolean, :default => false, :description => "generate an user specific controller and views"

      def create_controllers
        case true
        when options.user?
          # only admin
          admin_controller_template("admin_controller.rb")
          admin_controller_spec("spec/controller.rb")
        when options.admin?
          user_controller_template("user_controller.rb")
          user_controller_spec("spec/controller.rb")
        else
          admin_controller_template("admin_controller.rb")
          admin_controller_spec("spec/controller.rb")
          user_controller_template("user_controller.rb")
          user_controller_spec("spec/controller.rb")
        end
      end

      def copy_views
        # admin and user destination dir
        admin_dir_path = File.join("app/views/admin", controller_file_path)
        user_dir_path = File.join("app/views", controller_file_path)

        case true
        when options.admin?
          empty_directory user_dir_path
          user_view_files.each do |file_name|
            template "user_views/#{file_name}.html.erb", File.join(user_dir_path, "#{file_name}.html.erb")
          end
        when options.user?
          empty_directory admin_dir_path
          admin_view_files.each do |file_name|
            template "admin_views/#{file_name}.html.erb", File.join(admin_dir_path, "#{file_name}.html.erb")
          end
        else
          empty_directory user_dir_path
          user_view_files.each do |file_name|
            template "user_views/#{file_name}.html.erb", File.join(user_dir_path, "#{file_name}.html.erb")
          end

          empty_directory admin_dir_path
          admin_view_files.each do |file_name|
            template "admin_views/#{file_name}.html.erb", File.join(admin_dir_path, "#{file_name}.html.erb")
          end
        end
      end

      def add_routes
        case true
        when options.admin?
          # user routes
          route routes_only
        when options.user?
          # add routes as admin namespace
          insert_into_file "config/routes.rb", "\n\t\t\t#{routes_full}\n", :after => "get '', to: 'dashboard#index', as: '/'\n"
        else
          # user routes
          route routes_only
          # add routes as admin namespace
          insert_into_file "config/routes.rb", "\n\t\t\t#{routes_full}\n", :after => "get '', to: 'dashboard#index', as: '/'\n"
        end
      end

    end
  end
end
