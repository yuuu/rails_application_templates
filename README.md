# Rails Application Templates

My Rails application templates

## Usage

```
$ mkdir YOUR_RAILS_PROJECT && cd YOUR_RAILS_PROJECT
$ bundle init
$ bundle install --path vendor/bundle --jobs=4
```

for postgres

```
$ bundle exec rails new . --database=postgresql --skip-test-unit -m https://raw.githubusercontent.com/yuuu/rails-application-templates/master/app_template.rb
```

for mysql

```
$ bundle exec rails new . --database=mysql --skip-test-unit -m https://raw.githubusercontent.com/yuuu/rails-application-templates/master/app_template.rb
```

