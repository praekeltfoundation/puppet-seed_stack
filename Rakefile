require 'puppetlabs_spec_helper/rake_tasks'
require 'rubocop/rake_task'

RuboCop::RakeTask.new

task :librarian_spec_prep do
  sh 'librarian-puppet install --path=spec/fixtures/modules/'
end
task :spec_prep => :librarian_spec_prep

# Override puppetlabs_spec_helper's default lint settings
# * Don't want to ignore so many tests
# * Don't want to run lint on upstream modules
# See the .puppet-lint.rc file for checks that are skipped
Rake::Task[:lint].clear
PuppetLint::RakeTask.new(:lint) do |config|
  config.fail_on_warnings = true
  config.ignore_paths = [
    'modules/**/*.pp',
    'pkg/**/*.pp',
    'spec/**/*.pp',
    'vendor/**/*.pp',
  ]
end

# Coverage from puppetlabs_spec_helper requires rcov which doesn't work in
# anything since Ruby 1.8.7
Rake::Task[:coverage].clear

desc 'Run syntax, lint, metadata and spec tests.'
task :test => [
  :syntax,
  :spec,
  :lint,
  :metadata_lint,
  :rubocop,
]
