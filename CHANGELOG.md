# Changelog

## [1.2.2](https://github.com/panethjonathan8-ctrl/guestbook-app/compare/v1.2.1...v1.2.2) (2026-07-07)


### Bug Fixes

* resync VERSION with release-please manifest, add README ([#41](https://github.com/panethjonathan8-ctrl/guestbook-app/issues/41)) ([b2d7a3c](https://github.com/panethjonathan8-ctrl/guestbook-app/commit/b2d7a3cb6062d044613b331ca6c4933be8aa4be8)), closes [#40](https://github.com/panethjonathan8-ctrl/guestbook-app/issues/40)

## [1.2.1](https://github.com/panethjonathan8-ctrl/guestbook-app/compare/v1.2.0...v1.2.1) (2026-07-06)


### Bug Fixes

* correct promote-prod smoke test hostname ([#38](https://github.com/panethjonathan8-ctrl/guestbook-app/issues/38)) ([5322340](https://github.com/panethjonathan8-ctrl/guestbook-app/commit/5322340e0d5b22bd458c597e3e1ad1fd8230857c)), closes [#37](https://github.com/panethjonathan8-ctrl/guestbook-app/issues/37)

## [1.2.0](https://github.com/panethjonathan8-ctrl/guestbook-app/compare/v1.1.2...v1.2.0) (2026-07-06)


### Features

* add /stats endpoint returning total message count ([#35](https://github.com/panethjonathan8-ctrl/guestbook-app/issues/35)) ([0d914fc](https://github.com/panethjonathan8-ctrl/guestbook-app/commit/0d914fcbfbb7f09849337ff82c17c6f8ed29c840)), closes [#32](https://github.com/panethjonathan8-ctrl/guestbook-app/issues/32)

## [1.1.2](https://github.com/panethjonathan8-ctrl/guestbook-app/compare/v1.1.1...v1.1.2) (2026-07-06)


### Bug Fixes

* auto-merge with GH_RELEASE_PAT so release-please can re-trigger ([#30](https://github.com/panethjonathan8-ctrl/guestbook-app/issues/30)) ([939611f](https://github.com/panethjonathan8-ctrl/guestbook-app/commit/939611f0868cecaacc65461b3733b7bd2a73df8b)), closes [#29](https://github.com/panethjonathan8-ctrl/guestbook-app/issues/29)

## [1.1.1](https://github.com/panethjonathan8-ctrl/guestbook-app/compare/v1.1.0...v1.1.1) (2026-07-06)


### Bug Fixes

* authenticate release-please with a PAT so its Release PR gets real CI ([#27](https://github.com/panethjonathan8-ctrl/guestbook-app/issues/27)) ([b117fb7](https://github.com/panethjonathan8-ctrl/guestbook-app/commit/b117fb77e52902269bfc0d91ba3ec4e9c431f130)), closes [#26](https://github.com/panethjonathan8-ctrl/guestbook-app/issues/26)

## [1.1.0](https://github.com/panethjonathan8-ctrl/guestbook-app/compare/v1.0.1...v1.1.0) (2026-07-06)


### Features

* promote staging/prod by retagging release images instead of rebuilding ([#22](https://github.com/panethjonathan8-ctrl/guestbook-app/issues/22)) ([1e9c876](https://github.com/panethjonathan8-ctrl/guestbook-app/commit/1e9c876b0d2fb31e8acba898c47ecd754dd5e3fd)), closes [#21](https://github.com/panethjonathan8-ctrl/guestbook-app/issues/21)

## [1.0.1](https://github.com/panethjonathan8-ctrl/guestbook-app/compare/v1.0.0...v1.0.1) (2026-07-05)


### Bug Fixes

* scope deploy workflow trigger to actual app changes ([#19](https://github.com/panethjonathan8-ctrl/guestbook-app/issues/19)) ([a147605](https://github.com/panethjonathan8-ctrl/guestbook-app/commit/a147605c554431fc4faf8bac7b332857a691379d)), closes [#18](https://github.com/panethjonathan8-ctrl/guestbook-app/issues/18)

## 1.0.0 (2026-07-05)


### Features

* add Helm deploy step to deploy workflow ([#6](https://github.com/panethjonathan8-ctrl/guestbook-app/issues/6)) ([615bd89](https://github.com/panethjonathan8-ctrl/guestbook-app/commit/615bd89e2ee2cdecaefb5bad2df34658a98b7854))
* add pre-commit hooks and GitHub Actions CI/CD workflows ([12fdeb1](https://github.com/panethjonathan8-ctrl/guestbook-app/commit/12fdeb18d51070d7f08ff4a48ca8af025e769079))
* multi-environment promotion pipeline with smoke tests ([#13](https://github.com/panethjonathan8-ctrl/guestbook-app/issues/13)) ([65c42fe](https://github.com/panethjonathan8-ctrl/guestbook-app/commit/65c42fe0f019bcbdebcc31d87388887686ab0931)), closes [#12](https://github.com/panethjonathan8-ctrl/guestbook-app/issues/12)
* switch app database from SQLite to PostgreSQL ([#11](https://github.com/panethjonathan8-ctrl/guestbook-app/issues/11)) ([2bed281](https://github.com/panethjonathan8-ctrl/guestbook-app/commit/2bed281a97d4335055f373150752f7cc721f4101)), closes [#10](https://github.com/panethjonathan8-ctrl/guestbook-app/issues/10)


### Bug Fixes

* pin appuser to explicit UID/GID 1001 in Dockerfile ([#2](https://github.com/panethjonathan8-ctrl/guestbook-app/issues/2)) ([65917d3](https://github.com/panethjonathan8-ctrl/guestbook-app/commit/65917d32da0aa6d89461f0f738e6417101ccc982)), closes [#1](https://github.com/panethjonathan8-ctrl/guestbook-app/issues/1)
