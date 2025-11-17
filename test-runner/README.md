# Test Runner

This is the Go code invoked from the [test-runner-builder](https://github.com/codecrafters-io/test-runner-builder) Docker image.

Responsibilities:

- Builds the docker image that needs to executed to run tests for a challenge
- Also streams logs back to a logstream URL

### Testing Locally

This repository includes a fake server that can be used to test the test runner program locally.

- Install Ruby & Go
- `bundle install`
- `make refresh_test_fixtures` (downloads sample repositories)
- Ensure you're logged into the GitHub container registry by running this command: `docker login ghcr.io`.
  - The username is your github username.
  - The password is a GitHub access token with `read:packages` permissions (do **NOT** use your GitHub password here)
- Use `flyctl auth docker` to authenticate with Fly's Docker registry
- `docker compose up -d`
- `make test`

To run a specific test:

- `bundle exec ruby tests/run_tests_test.rb --verbose -n /when_/`

### Deploys

- Releases are automatically created on pushes to `main`
  - This happens via [./github/workflows/{tag,release}.yml](.github/workflows/tag.yml)
  - It takes 2-3 minutes for a release to be created after a push to `main`.
  - You can confirm that a release has been created by checking the [Releases](https://github.com/codecrafters-io/test-runner/releases) page.
- Ask Paul to deploy the release (this part isn't automated yet)
