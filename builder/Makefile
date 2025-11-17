current_patch_number := $(shell git tag --list "v0.3.*" | sort -V | tail -n 1 | cut -c 6-)
next_patch_number := $(shell echo $$(($(current_patch_number)+1)))
next_version_tag := v0.3.$(next_patch_number)

# Releases are automatically created on pushes to `main`, but this can be used to manually create a release.
release:
	git tag $(next_version_tag)
	git push origin main $(next_version_tag)

build_linux:
	# -mod=mod is required to ensure that go isn't confused by Ruby's vendor/bundle directory
	# CGO_ENABLED=0 ensures that the binary is statically linked and doesn't depend on any shared libraries
	GOOS=linux CGO_ENABLED=0 go build -mod=mod -o dist/main-linux.out ./

build_native:
	# -mod=mod is required to ensure that go isn't confused by Ruby's vendor/bundle directory
	# CGO_ENABLED=0 ensures that the binary is statically linked and doesn't depend on any shared libraries
	CGO_ENABLED=0 go build -mod=mod -o dist/main.out ./

build: build_linux build_native

print_next_version_tag:
	@echo $(next_version_tag) | tr -d '\n'

refresh_test_fixtures:
	rm -rf ./tests/fixtures
	mkdir -p ./tests/fixtures
	mkdir -p ./tests/fixtures/dockerfiles

	rm -rf /tmp/byo-redis
	git clone https://github.com/codecrafters-io/build-your-own-redis /tmp/byo-redis
	cd /tmp/byo-redis && git checkout 5ce64229f59108851de28c4f083f3459d58eff34

	rm -rf /tmp/byo-sqlite
	git clone https://github.com/codecrafters-io/build-your-own-sqlite /tmp/byo-sqlite
	cd /tmp/byo-sqlite && git checkout 8f419979fb7b3eb95cd2d0547f084032cf9edf39

	rm -rf ./tests/fixtures/redis-ruby-pass-stage-1
	cp -R /tmp/byo-redis/solutions/ruby/01-jm1/code ./tests/fixtures/redis-ruby-pass-stage-1
	cp /tmp/byo-redis/dockerfiles/ruby-3.3.Dockerfile ./tests/fixtures/dockerfiles/redis-ruby-3.3.Dockerfile

	rm -rf ./tests/fixtures/redis-rust-pass-stage-1
	cp -R /tmp/byo-redis/solutions/rust/01-jm1/code ./tests/fixtures/redis-rust-pass-stage-1
	cp /tmp/byo-redis/dockerfiles/rust-1.88.Dockerfile ./tests/fixtures/dockerfiles/redis-rust-1.88.Dockerfile

	rm -rf ./tests/fixtures/redis-go-pass-stage-1
	cp -R /tmp/byo-redis/solutions/go/01-jm1/code ./tests/fixtures/redis-go-pass-stage-1
	cp /tmp/byo-redis/dockerfiles/go-1.24.Dockerfile ./tests/fixtures/dockerfiles/redis-go-1.24.Dockerfile

	rm -rf ./tests/fixtures/sqlite-python-pass-stage-1
	cp -R /tmp/byo-sqlite/solutions/python/01-dr6/code ./tests/fixtures/sqlite-python-pass-stage-1
	cp /tmp/byo-sqlite/dockerfiles/python-3.13.Dockerfile ./tests/fixtures/dockerfiles/sqlite-python-3.13.Dockerfile

test: test_go test_build_image

test_go:
	# -mod=mod is required to ensure that go isn't confused by Ruby's vendor/bundle directory
	go test -mod=mod ./...

test_build_image: build
	bundle exec ruby tests/build_image_test.rb --verbose --fail-fast

