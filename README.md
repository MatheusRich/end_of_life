# End Of Life

This gem lists GitHub repositories using end-of-life Ruby versions.

## Installation

```sh
gem install end_of_life
```

## Usage

```
$ GITHUB_TOKEN=something eol
[✔] Fetching repositories...
[✔] Searching for EOL Ruby in repositories...

Found 2 repositories using EOL Ruby (<= 2.5.9):
┌───┬──────────────────────────────────────────────┬──────────────┐
│   │ Repository                                   │ Ruby version │
├───┼──────────────────────────────────────────────┼──────────────┤
│ 1 │ https://github.com/MatheusRich/my_rails_app  │ 2.5.8        │
│ 2 │ https://github.com/MatheusRich/some_repo     │ 2.5.0        │
└───┴──────────────────────────────────────────────┴──────────────┘
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run
`rake spec` to run the tests. You can also run `bin/console` for an interactive
prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To
release a new version, update the version number in `version.rb`, and then run
`bundle exec rake release`, which will create a git tag for the version, push
git commits and the created tag, and push the `.gem` file to
[rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/MatheusRich/end_of_life.

## License

The gem is available as open source under the terms of the [MIT
License](https://opensource.org/licenses/MIT).
