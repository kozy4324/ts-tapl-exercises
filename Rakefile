desc "Generate rbs files by rbs-inline"
task "rbs" do
  sh "bundle exec rbs-inline lib --output sig"
end

task :default => ["rbs"] do
  sh "ruby lib/chapter2/test_arith.rb"
end