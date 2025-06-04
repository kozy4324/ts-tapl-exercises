desc "Generate rbs files by rbs-inline"
task "rbs" do
  sh "rbs-inline lib --output sig" if system "which rbs-inline"
end

task :default => [:rbs, :chapter2, :chapter3]

task :chapter2 => ["rbs"] do
  sh "bundle exec ruby lib/chapter2/test_arith.rb"
end

task :chapter3 => ["rbs"] do
  sh "bundle exec ruby lib/chapter3/test_tiny_rb_parser.rb"
  sh "bundle exec ruby lib/chapter3/test_basic.rb"
end
