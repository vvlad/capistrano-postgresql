

set(:postgresql_repo, "deb http://apt.postgresql.org/pub/repos/apt/ trusty-pgdg main")
set(:postgresql_role, :db)


namespace :postgresql do

    task :defaults do

        set(:postgresql_packages, %w[postgresql-9.3 postgresql-9.3-postgis-2.1])
        paths = fetch(:templates_path, []) + [File.expand_path( "../../files/", __FILE__ )]
        set(:templates_path, paths)

    end

    task :sources do

      role = fetch(:postgresql_role)

      append_packages_for(role, fetch(:postgresql_packages))
      append_sources_for(role, repo: fetch(:postgresql_repo), pgp_key: "https://www.postgresql.org/media/keys/ACCC4CF8.asc")

    end

    task :users do

      on roles(:db) do

        pg_hba = file("pg_hba.conf")

        upload_as :postgres, pg_hba, "/etc/postgresql/9.3/main/pg_hba.conf"
        sudo "service postgresql reload"

        fetch(:postgresql_users,[]).each do |user|

          db_user = user.fetch(:username)
          db_pass = user.fetch(:password)
          db_name = user.fetch(:database, db_user)
          enconding = user.fetch(:enconding,  "utf-8")


          if capture(:psql, "-U", "postgres", "template1", "-t", "-c", "SELECT 1 FROM pg_catalog.pg_user WHERE usename = '#{db_user}'".shellescape).empty?
            execute :psql, "-U", "postgres", "-c", "CREATE ROLE #{db_user} LOGIN PASSWORD '#{db_pass}';".shellescape
          end

          if capture(:psql, "-U", "postgres", "template1", "-t", "-c", "SELECT 1 FROM pg_catalog.pg_database WHERE datname = '#{db_name}'".shellescape).empty?
            execute :psql, "-U", "postgres", "-c", "CREATE DATABASE #{db_name} ENCODING '#{enconding}' OWNER #{db_user};".shellescape
            execute :psql, "-U", "postgres", "#{db_name}", "-c", "CREATE EXTENSION postgis;".shellescape
          end
        end

      end

    end

end


after "load:defaults", "postgresql:defaults"
before "ubuntu:update_sources", "postgresql:sources"
after "ubuntu:install_packages", "postgresql:users"
