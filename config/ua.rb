fn = Rails.root.join('ua.config')
$ua = {}
$ua = YAML.load File.read fn if File.exist? fn
puts $ua.to_yaml

# if File.exist? "tmp/init_db_for_#{ENV['POSTGRES_DB']}"
if ActiveRecord::Base.connection.table_exists?(:users)

  if $ua['projects']
    $ua['projects'].each do |x|
      name = x['name']
      if name
        p = Project.where(name: name).first_or_create
        tasks = x['tasks']
        if tasks
          puts "found #{tasks.count} tasks"
          tasks.each do |x|
            name = x['name']
            if name
              t = Task.where(
                project_id: p.id,
                name: name,
                workflow_id: 0,
                kit_type_id: 0
              ).first_or_create
            end
          end
        else
          puts 'no tasks'
        end
      end
    end
  end
  
end
