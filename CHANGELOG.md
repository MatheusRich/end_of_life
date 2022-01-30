## [Unreleased]

### Added

- Fetch EOL Ruby versions from endoflife.date API. This ensures we always use up-to-date data but keep the embedded JSON as a fallback.

- Allow users to specify the maximum number of days away a version can be from EOL. It defaults to 0.

```sh
$ end_of_life --max-eol-days-away 90
```

- Add search methods to RubyVersion

It's possible to query all EOL versions, or the latest one at any given time.

```ruby
EndOfLife::RubyVersion.eol_versions_at(Date.today)
# =>
# [#<EndOfLife::RubyVersion:0x00007f9b1300d858
#   @eol_date=#<Date: 2021-03-31 ((2459305j,0s,0n),+0s,2299161j)>,
#   @version=Gem::Version.new("2.5.9")>,
#  #<EndOfLife::RubyVersion:0x00007f9b1300cea8
#   @eol_date=#<Date: 2020-03-31 ((2458940j,0s,0n),+0s,2299161j)>,
#   @version=Gem::Version.new("2.4.10")>,
#  #<EndOfLife::RubyVersion:0x00007f9b1300cb10
#   @eol_date=#<Date: 2019-03-31 ((2458574j,0s,0n),+0s,2299161j)>,
#   @version=Gem::Version.new("2.3.8")>,
#  #<EndOfLife::RubyVersion:0x00007f9b1300c5e8
#   @eol_date=#<Date: 2018-03-31 ((2458209j,0s,0n),+0s,2299161j)>,
#   @version=Gem::Version.new("2.2.10")>,
#  #<EndOfLife::RubyVersion:0x00007f9b1300c020
#   @eol_date=#<Date: 2017-03-31 ((2457844j,0s,0n),+0s,2299161j)>,
#   @version=Gem::Version.new("2.1.10")>,
#  #<EndOfLife::RubyVersion:0x00007f9b112efbb8
#   @eol_date=#<Date: 2016-02-24 ((2457443j,0s,0n),+0s,2299161j)>,
#   @version=Gem::Version.new("2.0.0.pre.p648")>,
#  #<EndOfLife::RubyVersion:0x00007f9b112ef028
#   @eol_date=#<Date: 2015-02-23 ((2457077j,0s,0n),+0s,2299161j)>,
#   @version=Gem::Version.new("1.9.3.pre.p551")>]

EndOfLife::RubyVersion.latest_eol # returns today's latest EOL version
# =>
# #<EndOfLife::RubyVersion:0x00007f9b1300d858
#  @eol_date=#<Date: 2021-03-31 ((2459305j,0s,0n),+0s,2299161j)>,
#  @version=Gem::Version.new("2.5.9")>

# returns the latest EOL version at a given date
EndOfLife::RubyVersion.latest_eol(at: Date.parse("2024-03-31"))
# =>
# #<EndOfLife::RubyVersion:0x00007f9b1300e7d0
#  @eol_date=#<Date: 2024-03-31 ((2460401j,0s,0n),+0s,2299161j)>,
#  @version=Gem::Version.new("3.0.3")>

EndOfLife::RubyVersion.new("3.0.0").eol?
# => false

EndOfLife::RubyVersion.new("3.0.0").eol?(at: Date.parse("2024-03-31"))
# => true
```

- Using the methods above, we can check whether a Repository is using EOL Ruby versions.

```ruby
# repo with Ruby 3.0 (which is not EOL today)
repo.eol_ruby?
# => false

repo.eol_ruby?(at: Date.parse("2024.04.04"))
# => true
```

### Changed

- `EndOfLife::RubyVersion::EOL` constant was removed in favor of `EndOfLife::RubyVersion.latest_eol` method.


----

## [0.2.0]

### Added

- Allow searching a specific repository.

```sh
$ end_of_life --repo=MatheusRich/ez_attributes
```

- Allow specifying the user used on the repository search.

```sh
$ end_of_life --user=matz # searches on matz's repositories
```

### Fixed

- Load end_of_life JSON database from dynamic path [#10](https://github.com/MatheusRich/end_of_life/pull/10).

  When installed on a fresh Ruby installation without the source code cloned,
  the JSON file couldn't be found because it was looking at the cwd of the
  running process instead of the Gem's lib directory path.

### Changed

- Exit with -1 if EOL repos are present.

- Upgrade `octokit` to v4.22, which fixes [a Faraday warning], so we can remove the dependency on the `warning` gem.

[a faraday warning]: https://github.com/octokit/octokit.rb/pull/1359

## [0.1.0]

- Initial release

[unreleased]: https://github.com/MatheusRich/end_of_life/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/MatheusRich/end_of_life/releases/tag/v0.2.0
[0.1.0]: https://github.com/MatheusRich/end_of_life/releases/tag/v0.1.0
