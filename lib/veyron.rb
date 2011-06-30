require 'net/http'
require 'highline/import'
require 'fileutils'

class Veyron
  
  attr_accessor :project_dir, :project_name, :github_username, :visibility, :veyron_dir
  
  def initialize
    @veyron_dir = File.expand_path(File.dirname(__FILE__))
    get_user_input
    create_repo
    say("**************************************************************")
    say("               THIS IS GOING TO TAKE ABOUT 20 MINS\n")
    say("                       GO MAKE A SANDWICH\n")
    say("**************************************************************")
    say("CREATING NEW RAILS PROJECT AT #{@project_path}")
    create_rails_project
    say("CREATING VAGRANT DIRECTORIES AND COPYING COOKBOOKS")
    vagrant_setup
    say("MAKING INITIAL COMMIT TO GITHUB")
    initial_commit
    say("**************************************************************")
    say("                       VAGRANT UP\n")
    say("**************************************************************")
    vagrant_up
    say("**************************************************************")
    say("                       VAGRANT SSH\n")
    say("**************************************************************")
    vagrant_ssh
    say("**************************************************************")
    say("               NOW, JUST cd TO /srv/PROJECT_NAME\n")
    say("                       AND rails s\n")
    say("**************************************************************")
  end
  
  def get_user_input
    @project_dir = ask("Where do you keep your projects? ex. /Users/chris/Projects: ")
    @project_name = ask("Project Name ex. my_new_project: ")
    @project_name = @project_name.squeeze.strip.gsub(" ", "_").downcase
    @project_path = "#{@project_dir}/#{@project_name}"
    @github_username = ask("GitHub username: ")
    @visibility = ask("Is this going to be a PRIVATE REPO? ( y / n )? ") { |q| q.validate = lambda {|r| r == 'y' || r == 'n'};
                                                                         q.responses[:not_valid] = "Please enter 'y' or 'n'"}
    @visibility = @visibility == 'y' ? 0 : 1
    return
  end
  
  def create_repo
    pw = ask("Enter password for GitHub accout #{@github_username}: ") { |q| q.echo = false }
    response = Net::HTTP.post_form(URI.parse("http://#{@github_username}:#{pw}@github.com/api/v2/json/repos/create"),
                                            {"name" => @project_name,
                                             "public" => @visibility})
    pw = nil
    case @visibility
      when 1
        say("Created PUBLIC GitHub repo #{@project_name} for #{@github_username}")
      when 0
        say("Created PRIVATE GitHub repo #{@project_name} for #{@github_username}")
    end
    return
  end
  
  def create_rails_project
    FileUtils.cd "#{@project_dir}"
    system("rails new #{@project_name} -d mysql -q")
  end
  
  def vagrant_setup
    FileUtils.cd "#{@project_path}"
    FileUtils.mkdir_p "vagrant"
    FileUtils.mkdir_p "data/cookbooks"
    FileUtils.mkdir_p "data/roles"
    FileUtils.cd "vagrant"
    FileUtils.cp "#{@veyron_dir}/../Vagrantfile", "#{@project_path}/vagrant/Vagrantfile"
    default_file = File.read("#{@project_path}/vagrant/Vagrantfile")
    updated_file = default_file.gsub("$PROJECT_NAME", "#{@project_name.downcase}")
    File.open("#{@project_path}/vagrant/Vagrantfile", "w") {|f| f.puts updated_file}
    FileUtils.cp_r "#{@veyron_dir}/../cookbooks", "#{@project_path}/data/"
    FileUtils.cp_r "#{@veyron_dir}/../roles", "#{@project_path}/data/"
    
    default_file = File.read("#{@project_path}/data/cookbooks/bundler/recipes/default.rb")
    updated_file = default_file.gsub("$PROJECT_NAME", "#{@project_name.downcase}")
    File.open("#{@project_path}/data/cookbooks/bundler/recipes/default.rb", "w") {|f| f.puts updated_file}
  end
  
  def initial_commit
    FileUtils.cd "#{@project_path}"
    system("git init")
    system("git add .")
    system("git commit -q -m 'initial commit'")
    system("git remote add origin git@github.com:#{@github_username}/#{@project_name}.git")
    system("git push origin master")
  end
  
  def vagrant_up
    FileUtils.cd "#{@project_path}/vagrant"
    system("vagrant up #{@project_name}")
  end
  
  def vagrant_ssh
    FileUtils.cd "#{@project_path}/vagrant"
    system("vagrant ssh #{@project_name}")
  end
end

Veyron.new