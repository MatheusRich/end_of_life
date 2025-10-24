# End of Life

This tool lists GitHub repositories using end-of-life software.

We currently support Ruby, Rails, and Node.js. If you want to add support for
more products, please check out the [Contributing](#contributing) section.

## Installation

## As a gem

If you have Ruby installed, you can install End of Life as a gem with:

```sh
gem install end_of_life
```

## Homebrew

If you're MacOS (>= 15 Sequoia) and use Homebrew, you can install it with:

```sh
brew tap MatheusRich/end_of_life
brew install end_of_life
```

> [!IMPORTANT]
> Please open an issue if you want to see installation support for other
> platforms or if you encounter any issues.

## Usage

### Scanning your repositories

1. Set up a [GitHub access token][] (we recommend using a read-only token);

[github access token]:
    https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token#creating-a-token

2. Export the `GITHUB_TOKEN` environment variable or set it when calling
   `end_of_life`;

3. Use the `end_of_life scan` command to list the repositories:

```sh
$ GITHUB_TOKEN=something end_of_life scan ruby
[✔] Searching repositories that might use Ruby...
[✔] Scanning 27 repositories for EOL Ruby...

Found 2 repositories using EOL Ruby (<= 3.1.7):
┌───┬──────────────────────────────────────────────┬──────────────┐
│   │ Repository                                   │ Ruby version │
├───┼──────────────────────────────────────────────┼──────────────┤
│ 1 │ https://github.com/MatheusRich/my_rails_app  │ 2.5.8        │
│ 2 │ https://github.com/MatheusRich/some_repo     │ 2.5.0        │
└───┴──────────────────────────────────────────────┴──────────────┘
```

> [!TIP]
> You can use the shorthand `eol` instead of `end_of_life` if your platform
> supports symlinks.

#### Options for `scan`

There are some options to help you filter down the results:

```sh
Usage: end_of_life scan PRODUCT [OPTIONS]
      --exclude=NAME,NAME2            Exclude repositories containing a certain word in their name. You can specify up to five words.
      --public-only                   Searches only public repositories
      --private-only                  Searches only private repositories
      --repo, --repository=USER/REPO  Searches a specific repository
      --org, --organization=ORG,ORG2  Searches within specific organizations
  -u, --user=NAME                     Sets the user used on the repository search
      --max-eol-days-away NUMBER      Sets the maximum number of days away a version can be from EOL.
      --include-archived              Includes archived repositories on the search
  -h, --help                          Show this help message
```

### Checking if a specific product version is EOL

> [!IMPORTANT]
> You don't need a GitHub token to use this command.

You can also check if a specific product version is end-of-life with the
`end_of_life check` command:

```sh
$ end_of_life check ruby@2.5.8 # exits with status code 1 on EOL
┌─────────────────┬────────┬──────────────────────────┐
│ Product Release │ Status │ EOL Date                 │
├─────────────────┼────────┼──────────────────────────┤
│ ruby@2.5.9      │ EOL    │ 2021-03-31 (4 years ago) │
└─────────────────┴────────┴──────────────────────────┘
```

You can pass multiple products to check at once:

```sh
$ end_of_life check ruby@2.5.8 nodejs@18
┌─────────────────┬────────┬───────────────────────────┐
│ Product Release │ Status │ EOL Date                  │
├─────────────────┼────────┼───────────────────────────┤
│ ruby@2.5.9      │ EOL    │ 2021-03-31 (4 years ago)  │
│ nodejs@18.20.8  │ EOL    │ 2025-04-30 (4 months ago) │
└─────────────────┴────────┴───────────────────────────┘
```

#### Options for `check`

```sh
Usage: end_of_life check PRODUCT@VERSION PRODUCT2@VERSION... [OPTIONS]
      --max-eol-days-away NUMBER      Sets the maximum number of days away a version can be from EOL.
  -h, --help                          Show this help message
```

> [!TIP]
> You can use check with the `--max-eol-days-away` option on your CI to be
> alerted when your current version is close to its end-of-life date:

```sh
$ end_of_life check ruby@$(ruby -v | awk '{print $2}') --max-eol-days-away=365
┌─────────────────┬──────────┬──────────────────────────┐
│ Product Release │ Status   │ EOL Date                 │
├─────────────────┼──────────┼──────────────────────────┤
│ ruby@3.2.9      │ Near EOL │ 2026-03-31 (in 6 months) │
└─────────────────┴──────────┴──────────────────────────┘
```

## How it works

This gem fetches all your GitHub repositories that contain code for the
specified product, then searches for files that may contain version information.
For Ruby, those files include `.ruby-version`, `Gemfile`, `Gemfile.lock`,
`mise.toml`, and `.tool-version`. End of Life parses these files and extracts
the minimum version used in each repository.

The EOL version information is provided by https://endoflife.date/.

> [!CAUTION]
> To parse Gemfiles, we need to execute the code inside them.
> **Be careful** because this may be a security risk. We plan to add secure
> parsers for these files in the future.

Some other limitations are listed on the [issues page].

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
https://github.com/MatheusRich/end_of_life. If you want to add a new product,
[check out this commit for reference].

[check out this commit for reference]: https://github.com/MatheusRich/end_of_life/commit/bfb6f9ceb5afb338fa5553a1266aa2c063e61200

## About thoughtbot

![thoughtbot](https://thoughtbot.com/thoughtbot-logo-for-readmes.svg)

The development of this project is funded by thoughtbot, inc.

We love open source software! See [our other projects][community]. We are
[available for hire][hire].

[community]: https://thoughtbot.com/community?utm_source=github
[hire]: https://thoughtbot.com/hire-us?utm_source=github

## License

The gem is available as open source under the terms of the [MIT
License](https://opensource.org/licenses/MIT).
