# Beans
An integration test suite for [Teiserver](https://github.com/beyond-all-reason/teiserver). Designed to be easily extended and contributed. Beans will fire up a set of concurrent modules and collate the results.

## Installation and usage
Beans does not require anything other than an [Elixir](https://elixir-lang.org/) installation and a Teiserver installation. Assuming you have elixir installed you should be able to run it like so:

```sh
git clone git@github.com:beyond-all-reason/beans.git
cd beans
mix deps.get
mix beans
```

The final command `mix beans` will run the Beans program and output the results.

## Development and contribution
Pull requests are welcome, there is [documentation](docs) and in particular an [adding new tests](docs/adding_new_tests.md) document which may be of use.

The Tachyon docs are located [here](https://github.com/beyond-all-reason/teiserver/tree/master/documents/tachyon).

## TODO
- Helper functions for website requests/tests
- More examples: Hosting a battle, Multiple connections at once
- The ability to selectively run only one/some tests
- Copy and modify the assert statements from ExUnit
