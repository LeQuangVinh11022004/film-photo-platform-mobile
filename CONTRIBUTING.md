# Contributing to AnalogAI

First off, thank you for considering contributing to **AnalogAI (Film Photography Platform)**! It's people like you that make AnalogAI such a great tool for the film photography community.

## 1. Where do I go from here?

If you've noticed a bug or have a feature request, make sure to check our [Issues](../../issues) page to see if someone else has already created a ticket. If not, go ahead and [make one](../../issues/new/choose)!

## 2. Fork & create a branch

If this is something you think you can fix, then [fork AnalogAI](https://docs.github.com/en/get-started/quickstart/fork-a-repo) and create a branch with a descriptive name.

A good branch name would be (where issue #325 is the ticket you're working on):

```sh
git checkout -b 325-add-darkroom-filter
```

## 3. Implementation Guidelines

*   **Ensure you are using the correct Flutter SDK version** specified in `pubspec.yaml`.
*   **Follow the Clean Architecture pattern:** Keep logic in `features/`, reusable components in `core/widgets/`, and API handling in `core/network/`.
*   **Adhere to Dart/Flutter conventions:** Run `flutter analyze` to ensure there are no linting errors.
*   **Write Tests:** If you are adding a new feature, please include widget or unit tests. Run `flutter test` to ensure all tests pass.

## 4. Make a Pull Request

At this point, you should switch back to your master branch and make sure it's up to date with AnalogAI's master branch:

```sh
git remote add upstream https://github.com/GFA26SE169_FA26SE091/film_photography_platform.git
git checkout master
git pull upstream master
```

Then update your feature branch from your local copy of master, and push it!

```sh
git checkout 325-add-darkroom-filter
git rebase master
git push --set-upstream origin 325-add-darkroom-filter
```

Finally, go to GitHub and [make a Pull Request](../../pulls) :D

## 5. Commit Message Convention

We follow the [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) specification.

*   `feat`: A new feature
*   `fix`: A bug fix
*   `docs`: Documentation only changes
*   `style`: Changes that do not affect the meaning of the code (white-space, formatting, missing semi-colons, etc)
*   `refactor`: A code change that neither fixes a bug nor adds a feature
*   `test`: Adding missing tests or correcting existing tests
*   `chore`: Changes to the build process or auxiliary tools and libraries such as documentation generation

Example: `feat: add booking cancellation functionality`
