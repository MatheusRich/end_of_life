# End of Life

This gem lists GitHub repositories using end-of-life versions of various
products.

![End of Life Demo](demo.gif)

## Installation

```sh
gem install end_of_life
```

## Usage

1. Set up a [GitHub access token][] (we recommend using a read-only token);

[github access token]:
    https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token#creating-a-token

2. Export the `GITHUB_TOKEN` environment variable or set it when calling
   `end_of_life`;

3. Use the `end_of_life` command to list the repositories:

```sh
$ GITHUB_TOKEN=something end_of_life # if your platform supports symlinks, you can use the `eol` command instead
[✔] Searching repositories with Ruby...
[✔] Searching for EOL Ruby in repositories...

Found 2 repositories using EOL Ruby (<= 3.1.7):
┌───┬──────────────────────────────────────────────┬──────────────┐
│   │ Repository                                   │ Ruby version │
├───┼──────────────────────────────────────────────┼──────────────┤
│ 1 │ https://github.com/MatheusRich/my_rails_app  │ 2.5.8        │
│ 2 │ https://github.com/MatheusRich/some_repo     │ 2.5.0        │
└───┴──────────────────────────────────────────────┴──────────────┘
```

### Options

There are some options to help you filter down the results:

```
Usage: end_of_life [options]
    -p, --product NAME                 Sets the product to scan for (default: ruby). Supported products are: ruby, rails.
        --exclude=NAME,NAME2           Exclude repositories containing a certain word in its name. You can specify up to five words.
        --public-only                  Searches only public repositories
        --private-only                 Searches only private repositories
        --repo, --repository=USER/REPO Searches a specific repository
        --org, --organization=ORG,ORG2 Searches within specific organizations
    -u, --user=NAME                    Sets the user used on the repository search
        --max-eol-days-away NUMBER     Sets the maximum number of days away a version can be from EOL. It defaults to 0.
        --include-archived             Includes archived repositories on the search
    -v, --version                      Displays end_of_life version
    -h, --help                         Displays this help
```

## How it works

This gem fetches all your GitHub repositories that contain code for the
specified product, then searches for files that may contain version information.
For Ruby, those files are: `.ruby-version`, `Gemfile`, `Gemfile.lock`, and
`.tool-version`. End of Life parses these files and extracts the minimum version
used in the repository.

The EOL version information is provided by https://endoflife.date/, with a file
[fallback].

> [!CAUTION]
> To parse Gemfiles, we need to execute the code inside them.
> **Be careful** because this may be a security risk. We plan to add secure
> parsers for these files in the future.

Some other limitations are listed on the [issues page].

[fallback]: ./lib/end_of_life.json
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

[check out this commit for reference]: ba9a92a690e0d61ea09e508c1cd76b8309fb89df

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
