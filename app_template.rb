require 'bundler'

def setup_gemfile
  gem 'paranoia', '~> 2.0' # 論理削除
  gem 'kaminari' # ページネーション
  gem 'exception_notification' # エラー通知
  gem 'exnum' # enum拡張
  gem 'roshi' # 日本語バリデーション
  gem 'config' # 定数管理
  
  # Use Unicorn as the app server
  gem 'unicorn'
  gem 'unicorn-worker-killer'
  
  # 認証
  if yes?('Would you like to install devise?')
    gem 'devise'
    gem 'devise-bootstrap-views'
    gem 'devise-i18n'
    gem 'devise-i18n-views'
  end
  
  # I18n
  if yes?('Would you like to install I18n?')
    gem 'rails-i18n'
    gem 'i18n-tasks'
  end
  
  # API
  @use_api = ask('Would you like to use API?')
  if @use_api == 'yes'
    gem 'grape', '~> 1.0.3'
    gem 'grape-swagger', '~> 0.29.0'
  end
  
  # Javascript
  if yes?('Would you like to use Javascript?')
    gem 'i18n-js'
    gem 'gon'
    gem 'bootsnap'
    gem 'foreman', '~> 0.84.0'
  end
  
  gem_group :development, :test do
    gem 'pry-rails' # REPL
    gem 'pry-stack_explorer'
    gem 'better_errors'
    gem 'rubocop', require: false
    gem 'letter_opener_web'
  
    # Rspec
    gem 'rspec-rails'
    gem 'capybara'
    gem 'turnip'
    gem 'factory_bot_rails'
    gem 'database_cleaner'
  end
  
  gem_group :development do
    gem 'foreman', '~> 0.84.0'
  
    # Deploy
    gem 'capistrano', '~> 3.8', '>= 3.8.1'
    gem 'capistrano-bundler', '~> 1.2'
    gem 'capistrano-rails', '~> 1.3'
    gem 'capistrano-rbenv', '~> 2.1', '>= 2.1.1'
    gem 'capistrano-deploytags', '~> 1.0.6', require: false
    gem 'slackistrano'
  end
end

def setup_application_config
  str = %q{
    config.time_zone = 'Tokyo'
    config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}').to_s]
    config.i18n.default_locale = :ja
  }
  if @use_api == 'yes'
    str += %q{
      config.paths.add File.join('app', 'api'), glob: File.join('**', '*.rb')
      config.autoload_paths += Dir[Rails.root.join('app', 'api', '*')]
    }
  end
  str += %q{
    config.generators do |g|
      g.orm :active_record
      g.test_framework :rspec, fixture: true
      g.fixture_replacement :factory_girl, dir: 'spec/factories'
      g.view_specs false
      g.controller_specs false
      g.routing_specs false
      g.helper_specs false
      g.request_specs false
      g.assets false
      g.helper false
    end
  }
  application { str }
end

def setup_rubocop
  # setup rubocop
  create_file '.rubocop.yml', <<RUBOCOP
Rails:
  Enable: true
AllCops:
  TargetRubyVersion: 2.4.2
  Exclude:
    - 'db/**/*'
    - 'config/**/*'
    - 'script/**/*'
    - 'vendor/**/*'
    - 'bin/*'
    - !ruby/regexp /old_and_unused\.rb$/
    - 'spec/**/*'
    - 'Gemfile'
    - 'Gemfile.lock'
    - 'Rakefile'
    - 'Capfile'
    - 'lib/capistrano/tasks/unicorn.rake'
    - 'lib/tasks/**/*.rake'
    - 'node_modules/**/*'

Bundler/DuplicatedGem:
  Exclude:
    - 'Gemfile'

Style/AsciiComments:
  Enabled: false

Style/SymbolArray:
  Enabled: false

Style/FrozenStringLiteralComment:
  Enabled: false

Style/Documentation:
  Enabled: false

Style/EmptyMethod:
  Enabled: false

Style/ClassAndModuleChildren:
  Enabled: false

Style/WordArray:
  EnforcedStyle: brackets

Style/NumericPredicate:
  Enabled: false

Style/NumericLiterals:
  Enabled: false

Style/RedundantSelf:
  Enabled: false

Metrics/LineLength:
  Max: 100

Metrics/MethodLength:
  Max: 20
RUBOCOP
end

def setup_turnip_helper
  create_file 'spec/turnip_helper.rb', <<RUBY
ENV["RAILS_ENV"] ||= 'test'

require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'capybara/rails'

require 'capybara'
require 'capybara/poltergeist'

require 'turnip'
require 'turnip/capybara'
require 'turnip/rspec'

require 'factory_bot_rails'

require 'database_cleaner'

# using driver (need phantomjs)
Capybara.current_driver = :poltergeist
Capybara.default_driver = :poltergeist
Capybara.javascript_driver = :poltergeist
Capybara.run_server = true

# web driverの設定
Capybara.register_driver :poltergeist do |app|
  Capybara::Poltergeist::Driver.new(app, {js_errors: false, default_wait_time: 30, timeout: 100})
end

Dir.glob("spec/**/*steps.rb") { |f| load f, true }

RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods
  config.use_transactional_fixtures = false

  config.before(:suite) do
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.clean_with :truncation
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end

  config.after(:suite) do
    DatabaseCleaner.clean
  end
end
RUBY
end

def setup_procfile
  # Procfile
  create_file 'spec/turnip_helper.rb', <<PROCFILE
rails: bundle exec rails server
webpack: ./bin/webpack-dev-server%
PROCFILE
end

def setup_git
  git :init
  git add: "."
  git commit: "-m First commit!"
  @app_name = app_name
  @remote_repo = ask("git remote repo?")
  git :remote => "add origin #@remote_repo:#@app_name.git"
end


## .gitignore
run 'wget -O .gitignore https://raw.githubusercontent.com/github/gitignore/master/Rails.gitignore'

# install gems
setup_gemfile
run 'bundle install --path vendor/bundle --jobs=4'

# install locales
remove_file 'config/locales/en.yml'
run 'wget https://raw.github.com/svenfuchs/rails-i18n/master/rails/locale/en.yml -P config/locales/'
run 'wget https://raw.github.com/svenfuchs/rails-i18n/master/rails/locale/ja.yml -P config/locales/'

# config/application.rb
setup_application_config

# Remove files
remove_file 'README.rdoc'

# Remove comment and empty lines
empty_line_pattern = /^\s*\n/
comment_line_pattern = /^\s*#.*\n/

gsub_file 'Gemfile', comment_line_pattern, ''
gsub_file 'config/application.rb', comment_line_pattern, ''
gsub_file 'config/routes.rb', comment_line_pattern, ''
gsub_file 'config/routes.rb', empty_line_pattern, ''
gsub_file 'config/database.yml', comment_line_pattern, ''

after_bundle do
  generate 'rspec:install'
  setup_turnip_helper
  setup_rubocop
  setup_procfile
  setup_git
end


