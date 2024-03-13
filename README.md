# Hailstorm
An integration test suite for [Teiserver](https://github.com/beyond-all-reason/teiserver). Designed to be easily extended and contributed. Hailstorm will fire up a set of concurrent modules and collate the results.

## Installation and usage
Hailstorm does not require anything other than an [Elixir](https://elixir-lang.org/) installation and a Teiserver installation; if you are running Teiserver locally you already have everything you need to run Hailstorm.

```sh
git clone git@github.com:beyond-all-reason/hailstorm.git
cd hailstorm
mix deps.get
mix test
```

The final command `mix test` will run the unit tests which work as the integration tests for Teiserver. Note: You will need to have Teiserver running at the time to perform these tests.

## Run specific tests
```
mix balance_test
```
Will run the balance tests only

## Development and contribution
Pull requests are welcome, there is [documentation](docs) and in particular an [adding new tests](docs/adding_new_tests.md) document which may be of use.

The Tachyon repo is located at [github.com/beyond-all-reason/tachyon](https://github.com/beyond-all-reason/tachyon).
