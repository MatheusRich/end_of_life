# EolRuby

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/eol_ruby`. To experiment with that code, run `bin/console` for an interactive prompt.

TODO: Delete this and the text above, and describe your gem

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'eol_ruby'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install eol_ruby

## Usage

TODO: Write usage instructions here

### As a CLI

```sh
$ GITHUB_TOKEN=something eol_ruby
REPO                 RUBY_VERSION
playground           2.0.0
rails_demo           2.5.1
my_org/shiny_thing   2.2.2

$ GITHUB_TOKEN=something eol_ruby --exclude=rails_demo,shiny_thing
REPO          RUBY_VERSION
playground    2.0.0

$ GITHUB_TOKEN=something eol_ruby --exclude=my_org
REPO          RUBY_VERSION
playground    2.0.0
rails_demo    2.5.1
```

### As a library

```sh
EolRuby.
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/eol_ruby.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
