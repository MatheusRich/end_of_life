## [Unreleased]

### Added

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

## [0.1.0] - 2022-01-17

- Initial release

[unreleased]: https://github.com/MatheusRich/end_of_life/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/MatheusRich/end_of_life/releases/tag/v0.1.0
