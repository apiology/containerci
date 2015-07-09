# ContainerCI

This is a toolkit for creating automated builds for Docker containers via the magic of Rakefiles.

It will pull from a given tag from the project which you are containerizing, use Docker and your Dockerfile to build, run tests that you define, and push to DockerHub.

With the below sample circle.yml, you can use CircleCI to automate this process and build your container whenever your source project changes and passes its tests.

ContainerCI currently supports a pretty limited workflow for a container in CircleCI (i.e., something I needed to do twice), but contributions are welcome!

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'containerci'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install containerci

## Usage

1) Add this line to your application's Rakefile:

```ruby
require 'containerci'

ContainerCI::ExportGithubProjectIntoContainer.new
```

2) Create a circle.yml file that looks like this:


```yaml
machine:
 services:
   - docker
 post:
   - 'echo "{ \"https://index.docker.io/v1/\": { \"auth\": \"$DOCKERHUB_TOKEN\", \"email\": \"$DOCKERHUB_EMAIL\" }}" > ~/.dockercfg'
dependencies:
  cache_directories:
    - "sinatra-vld"
    - "~/docker"
    - "~/docker-machine"
  post:
    - bundle exec rake dependencies
test:
  override:
    - bundle exec rake test quality
deployment:
  staging:
    branch: master
    commands:
      - bundle exec rake after_test_success
```

3) Define tasks for :deploy (or change/remove the deployment section of the below
circleci.yml file).

4) Define a task for :test to test your container before it is tagged and
pushed to Docker Hub.

5) Verify it works.

6) Set up a trigger to build your container project when the source project succesfully builds (see below). 

## Setting up CircleCI automated build triggers

When your source project succesfully builds and passes tests, you're going to want to rebuild the container with the resulting files.  Add this to your source project (not the one you're using this gem with!):

```yaml
deployment:
  staging:
    branch: master
    commands:
      - bundle exec rake after_test_success
```

Now add these tasks to your Rakefile:

```ruby
# this is run by CircleCI
task after_test_success: [:tag, :trigger_next_builds]

task :tag do
  sh 'git tag -f tests_passed'
  sh 'git push -f origin tests_passed'
end

GITHUB_USER = 'you'
DOWNSTREAM_GITHUB_PROJECT = 'your-container-project'

task :trigger_next_builds do
  sh "curl -v -X POST https://circleci.com/api/v1/project/#{GITHUB_USER}/" \
     "#{DOWNSTREAM_GITHUB_PROJECT}/tree/master?circle-token=$CIRCLE_TOKEN"
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake rspec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

### To test quality
  ```rake localtest```

### To run tests alone
  ```rake feature```
  ```rake spec```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/apiology/containerci. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

