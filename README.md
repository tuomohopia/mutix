```sh
iex -S mix test
```

Code modules have to be loaded explicitly `run([..])`, because otherwise they're
already required and will not run.

```elixir
Interactive Elixir (1.15.5) - press Ctrl+C to exit (type h() ENTER for help)
iex> ExUnit.start(autorun: false)
:ok
iex> ExUnit.run([MutixTest])
....
Finished in 0.8 seconds (0.00s async, 0.8s sync)
4 tests, 0 failures

Randomized with seed 957366
%{total: 4, failures: 0, excluded: 0, skipped: 0}
```

May have to run `ExUnit.Server.modules_loaded(false)`.

## Compilation

- `Code.compile_string(..)` ja `Code.compile_quoted(..)` ylikirjoittaa jo
  olemassa olevan moduulin päälle
- use `Macro.to_string()` to convert the quoted, mutated line back to string

## POC

- Input: lib module file path & test file path
- Creates a mutation of a single + operator to -
- Runs the test file suite against the mutation, sending records to recorder
- Repeats the above for every mutation
- Result:
  - File & Line changed
  - how many test failures out of total
  - Mutation Score
  - at least 1 test needs to fail for each mutant
  - Line-by-line analysis which mutant was not caught by any test

### Development steps

### Problems

Run ExUnit multiple times:
https://stackoverflow.com/questions/36926388/how-can-i-avoid-the-warning-redefining-module-foo-when-running-exunit-tests-m
