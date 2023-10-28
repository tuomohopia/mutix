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
