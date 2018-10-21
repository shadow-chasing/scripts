
module ScAdminScaffold
  module Generators
    # Custom scaffold generator
    class DashboardGenerator < Rails::Generators::NamedBase
      include Rails::Generators::ResourceHelpers

      source_root File.expand_path('../dashboard_templates', __FILE__)

      desc "Generates admin dashboard"

      def copy_controller
        # create admin dir
        empty_directory "app/controllers/admin"

        # move templated admin controller to admin dir. NOTE this is probably plural - @title maybe needed.
        template "controller.rb", File.join("app/controllers/admin", "#{@file_name}_controller.rb")
      end

      # create view under admin namespace.
      def copy_view_files
        directory_path = File.join("app/views/admin", @file_name)
        empty_directory directory_path

        # copy index file
        copy_file "dashboard/views/index.html.erb", File.join(directory_path, "index.html.erb")
      end

      def copy_scss
        # copy admin style sheet.
        copy_file "_admin.scss", "app/assets/stylesheets/_admin.scss"
      end

      def create_admin_partials
        partial_path = "app/views/admin/partials"
        empty_directory partial_path
        copy_file "_aside.html.erb", File.join(partial_path, "_aside.html.erb")
      end

      def devise_config
        # devise login
        generate 'devise:install'
        generate 'devise User'

        rake 'db:migrate'

        # add username to users
        generate 'migration add_username_to_users username:string:uniq'

        # generate admin/user views
        generate 'devise:views admin/users'

        # generate devise controllers
        generate 'devise:controllers admin/users'
      end

      def copy_migrations
        copy_file "20181018144950_add_articles_count_to_user.rb", "db/migrate/20181018144950_add_articles_count_to_user.rb"
        copy_file "20180906142847_add_trackable_columns_to_user.rb", "db/migrate/20180906142847_add_trackable_columns_to_user.rb"
        rake 'db:migrate'
      end


      def add_authentication_key
        # config/initializers/devise - add authentication_keys for devise login.
        insert_into_file('config/initializers/devise.rb', "\nconfig.authentication_keys = [ :login ]\n", :after => /# config.omniauth_path_prefix = '\/my_engine\/users\/auth'/)
      end

      def remove_redundant_devise_controllers
        remove_file "app/views/admin/users/registrations"
        remove_file "app/views/admin/users/sessions"
      end

      def move_new_devise_controllers
        directory "devise/registrations", "app/views/admin/users/registrations"
        directory "devise/sessions", "app/views/admin/users/sessions"
      end

      def replace_registrations_controller
        remove_file 'app/controllers/admin/users/registrations_controller.rb'
        copy_file "devise/registrations_controller.rb", "app/controllers/admin/users/registrations_controller.rb"
      end

      def replace_user_model
        remove_file 'app/models/user.rb'
        copy_file "user.rb", "app/models/user.rb"
      end

      def remove_incorrect_namspace
        gsub_file 'config/routes.rb', /[d](e|v|i|s){5}\_[f].*/, ""
        gsub_file 'config/routes.rb', /g[a-z]{2}\s\'[d].*\/[i].*\'/, "\tget '', to: 'dashboard#index', as: '/'\n"
      end

      # Append dashboard and devise controller routes.
      def append_to_route
        insert_into_file "config/routes.rb", :after => "Rails.application.routes.draw do\n" do

          "\n

          namespace \:admin do\n
            # admin dashboard\n
            get \'\', to\: \'dashboard#index\', as\: \'\/\'\n

            # devise\n
            devise_for \:users, controllers\: { sessions\: \'admin\/users\/sessions\', registrations\: \'admin\/users\/registrations\'}\n
          end

          \n"
        end

      end
    end
  end
end
