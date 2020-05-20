require "bundler/gem_tasks"
require "rake/testtask"
require "rubocop/rake_task"
require "dry/types/version"

task default: %i[test]

TEST_WITH_OLD_AND_NEW_API = %w[
  validation/dry_validation call composition contract errors inherit module reform
  save skip_if populate validate form
].freeze

def dry_v_test_files
  dry_v_version = Gem::Version.new(Dry::Types::VERSION)
  api = dry_v_version > Gem::Version.new("0.13.3") ? "new" : "old"
  TEST_WITH_OLD_AND_NEW_API.map { |file| "test/#{file}_#{api}_api.rb" }
end

Rake::TestTask.new(:test) do |test|
  test.libs << "test"
  test.test_files = FileList["test/*_test.rb"] + FileList["test/validation/*_test.rb"] + dry_v_test_files
  test.verbose = true
end

RuboCop::RakeTask.new(:rubocop)
