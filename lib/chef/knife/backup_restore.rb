#
# Author:: Marius Ducea (<marius.ducea@gmail.com>)
# Author:: Steven Danna (steve@opscode.com)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

class Chef
  class Knife
    class CookbookUpload < Knife
      def check_for_dependencies!(cookbook)
      end
    end
  end
end


module ServerBackup
  class BackupRestore < Chef::Knife

    deps do
      require 'chef/knife/core/object_loader'
      require 'chef/cookbook_uploader'
      require 'chef/api_client'
      require 'securerandom'
      require 'json'
    end

    banner "knife backup restore [COMPONENT [COMPONENT ...]] [-D DIR] (options)"

    option :backup_dir,
      :short => "-D DIR",
      :long => "--backup-directory DIR",
      :description => "Restore backup data from DIR.",
      :default => Chef::Config[:knife][:chef_server_backup_dir] ? Chef::Config[:knife][:chef_server_backup_dir] : File.join(".chef", "chef_server_backup")

    def run
      ui.warn "This will overwrite existing data!"
      ui.warn "Backup is at least 1 day old" if (Time.now - File.atime(config[:backup_dir])) > 86400
      ui.confirm "Do you want to restore backup, possibly overwriting exisitng data"
      validate!
      components = name_args.empty? ? COMPONENTS : name_args
      Array(components).each { |component| self.send(component) }
    end

    private
    COMPONENTS = %w(clients users nodes roles data_bags environments cookbooks)

    def validate!
      bad_names = name_args - COMPONENTS
      unless bad_names.empty?
        ui.error "Component types #{bad_names.join(",")} are not valid."
        exit 1
      end
    end

    def nodes
      restore_standard("nodes", Chef::Node)
    end

    def roles
      restore_standard("roles", Chef::Role)
    end

    def environments
      restore_standard("environments", Chef::Environment)
    end

    def data_bags
      ui.info "=== Restoring data bags ==="
      loader = Chef::Knife::Core::ObjectLoader.new(Chef::DataBagItem, ui)
      dbags = Dir.glob(File.join(config[:backup_dir], "data_bags", '*'))
      dbags.each do |bag|
        bag_name = File.basename(bag)
        ui.info "Restoring data_bag[#{bag_name}]"
        begin
          rest.post_rest("data", { "name" => bag_name})
        rescue Net::HTTPServerException => e
          handle_error 'data_bag', bag_name, e
        end
        dbag_items = Dir.glob(File.join(bag, "*"))
        dbag_items.each do |item_path|
          item_name = File.basename(item_path, '.json')
          ui.info "Restoring data_bag_item[#{bag_name}::#{item_name}]"
          item = loader.load_from("data_bags", bag_name, item_path)
          dbag = Chef::DataBagItem.new
          dbag.data_bag(bag_name)
          dbag.raw_data = item
          dbag.save
        end
      end

    end

    def restore_standard(component, klass)
      loader = Chef::Knife::Core::ObjectLoader.new(klass, ui)
      ui.info "=== Restoring #{component} ==="
      files = Dir.glob(File.join(config[:backup_dir], component, "*.json"))
      files.each do |f|
        ui.info "Restoring #{component} from #{f}"
        updated = loader.load_from(component, f)
        updated.save
      end
    end

    def clients
      JSON.create_id = "no_thanks"
      ui.info "=== Restoring clients ==="
      clients = Dir.glob(File.join(config[:backup_dir], "clients", "*.json"))
      clients.each do |file|
        client = JSON.parse(IO.read(file))
        begin
          rest.post_rest("clients", {
            :name => client['name'],
            :public_key => client['public_key'],
            :admin => client['admin'],
            :validator => client['validator']
          })
        rescue Net::HTTPServerException => e
          handle_error 'client', client['name'], e
        end
      end
    end

    def users
      JSON.create_id = "no_thanks"
      ui.info "=== Restoring users ==="
      users = Dir.glob(File.join(config[:backup_dir], "users", "*.json"))
      if !users.empty? and Chef::VERSION !~ /^1[1-9]\./
        ui.warn "users restore only supported on chef >= 11"
        return
      end
      users.each do |file|
        user = JSON.parse(IO.read(file))
        password = SecureRandom.hex[0..7]
        begin
          rest.post_rest("users", {
            :name => user['name'],
            :public_key => user['public_key'],
            :admin => user['admin'],
            :password => password
          })
          ui.info "Set password for #{user['name']} to #{password}, please update"
        rescue Net::HTTPServerException => e
          handle_error 'user', user['name'], e
        end
      end
    end

    def cookbooks
      ui.info "=== Restoring cookbooks ==="
      cookbooks = Dir.glob(File.join(config[:backup_dir], "cookbooks", '*'))
      cookbooks.each do |cb|
        full_cb = File.expand_path(cb)
        cb_name = File.basename(cb)
        cookbook = cb_name.reverse.split('-',2).last.reverse
        full_path = File.join(File.dirname(full_cb), cookbook)

        begin
          File.symlink(full_cb, full_path)
          cbu = Chef::Knife::CookbookUpload.new
          Chef::Knife::CookbookUpload.load_deps
          cbu.name_args = [ cookbook ]
          cbu.config[:cookbook_path] = File.dirname(full_path)
          ui.info "Restoring cookbook #{cbu.name_args}"
          cbu.run
        rescue Net::HTTPServerException => e
          handle_error 'cookbook', cb_name, e
        ensure
          File.unlink(full_path)
        end
      end
    end

    def handle_error(type, name, error)
      thing = "#{type}[#{name}]"
      case error.response
      when Net::HTTPConflict # 409
        ui.warn "#{thing} already exists; skipping"
      when Net::HTTPClientError # 4xx Catch All
        ui.error "Failed to create #{thing}: #{error.response}; skipping"
      else
        ui.error "Failed to create #{thing}: #{error.response}; skipping"
      end
    end

  end
end
