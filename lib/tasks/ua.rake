namespace :ua do
  base = '/Users/jdwright/github/ua20250904'
  task :init do
    %w[
      app/models
      app/helpers
      app/assets/stylesheets
      app/channels/application_cable
      app/controllers/concerns
      app/javascript
      app/mailers
      app/views/layouts
      bin
      config/initializers
      config/environments
      db/migrate
    ].each do |x|
      mkdir_p x
    end
    %w[
      .gitignore
      components.json
      Dockerfile
      docker-compose.yml
      Gemfile
      Gemfile.lock
      jsconfig.json
      package.json
      postcss.config.js
      Procfile.dev
      tailwind.config.ts
      ua.config
      vite.config.ts
      app/assets/stylesheets/application.css
      app/channels/application_cable/connection.rb
      app/channels/application_cable/channel.rb
      app/controllers/concerns/authentication.rb
      app/javascript/mount.js
      app/javascript/settings.js
      app/javascript/users.js
      app/javascript/modal.svelte
      app/mailers/passwords_mailer.rb
      app/views/layouts/application.html.haml
      app/views/layouts/_header.html.haml
      bin/vite
      config/initializers/content_security_policy.rb
      config/vite.json
      config/routes.rb
      config/environment.rb
      config/environments/development.rb
      config/environments/production.rb
      config/application.rb
      config/ua.rb
      db/seeds.rb
    ].each do |x|
      cp "#{base}/#{x}", x
    end
    %w[
      current
      feature
      group_user
      group
      project_user
      project
      session
      task_user
      task
      user
    ].each do |x|
      f = "app/models/#{x}.rb"
      cp "#{base}/#{f}", f
      case x
      when 'current'
        next
      else
        f = "app/controllers/#{x}s_controller.rb"
        cp "#{base}/#{f}", f
      end
    end
    %w[
      application
      pages
      passwords
      cognito_token
      jwts
    ].each do |x|
      f = "app/controllers/#{x}_controller.rb"
      cp "#{base}/#{f}", f
    end
    %w[
      sessions
      users
    ].each do |x|
      f = "app/helpers/#{x}_helper.rb"
      cp "#{base}/#{f}", f
    end
    %w[
      app/javascript/entrypoints
      app/javascript/users
      app/javascript/work
      app/javascript/lib
      app/javascript/src
      app/javascript/channels
      app/javascript/components
      app/views/passwords
      app/views/passwords_mailer
      app/views/sessions
      app/views/shared
      app/views/users
    ].each do |x|
      mkdir_p x
      case x
      when /java/
        cp_r "#{base}/#{x}", "app/javascript"
      else
        cp_r "#{base}/#{x}", "app/views"
      end
    end
    %w[
      app/views/layouts/application.html.erb
    ].each do |x|
      rm x if File.exist? x
    end
    name = JSON.parse(File.read("app/views/pwa/manifest.json.erb"))['name']
    app = File.read "config/application.rb"
    File.write "config/application.rb", app.sub(/module .+/, "module #{name}")
  end
  task :setup do
    sh "docker compose exec web bin/rails g migration NewSetup"
    cp `ls #{base}/db/migrate/*`.chomp, `ls db/migrate/*`.chomp
  end
  task :prepare do
    sh "docker compose exec web bin/rails db:prepare"
    sh "docker compose exec web bun i"
  end
end
