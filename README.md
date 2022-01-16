# End Of Life

This gem lists GitHub repositories using end-of-life Ruby versions.

## Installation

```sh
gem install end_of_life
```

## Usage

1. Set up a [GitHub access token];

[GitHub access token]: https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token#creating-a-token

2. Export the `GITHUB_TOKEN` environment variable or set it when calling `end_of_life`;

3. Use the `end_of_life` command to list the repositories:
```sh
$ GITHUB_TOKEN=something end_of_life # if your platform supports symlinks, you can use the `eol` command instead
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

## How it works?

This gem fetches all your GitHub repositories that contain Ruby code, then
searches for files that may have a Ruby version. Currently, those files are:
`.ruby-version`, `Gemfile`, `Gemfile.lock`, and `.tool-version`. We parse these
files and extract the minimum Ruby version used in the repository.

The EOL Ruby version is defined statically in [this JSON file] provided by
https://endoflife.date/. We plan to fetch their API endpoint in the future.

> **IMPORTANT:** To parse Gemfiles, we need to execute the code inside it. **Be
> careful** because this may be a security risk. We plan to add a secure parser
> for Gemfiles in the future.

Some other limitations are listed on the [issues page].

[this json file]: ./lib/end_of_life.json
[issues page]: https://github.com/MatheusRich/end_of_life/issues

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
