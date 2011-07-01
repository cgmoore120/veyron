bash "sudo gem install bundler" do
  code "sudo gem install bundler"
end

bash "bundle install" do
  code <<-EOC
    cd /srv/$PROJECT_NAME
    bundle install
  EOC
end