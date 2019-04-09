# Releasing a New Version

## Checklist

- Ensure `CHANGELOG.md` is up-to-date
- Ensure working dir is clean
- Run `mix format` and `mix credo` for formatting and linting
- Ensure the docs look acceptable using `mix docs`
- Run `prettier` on all markdown files
- Update version requirement in `README.md`
- Update version in `mix.exs`
- Create a commit:

        git commit -a -m "Bump version to 0.X.Y"
        git tag v0.X.Y
        mix compile --warnings-as-errors && mix test && mix hex.publish
        git push origin master --tags

- Enjoy!
