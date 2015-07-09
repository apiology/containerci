# ContainerCI

This is a toolkit for creating automated builds for Docker containers.

It will pull from a given tag from the project which you are containerizing, use Docker and your Dockerfile to build, run tests that you define, and push to DockerHub.

With the below circle.yml, you can use CircleCI to automate this process and build your container whenever your source project changes and passes its tests.

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

Add this line to your applicatoin's Rakefile:

```ruby
require 'containerci'
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

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/container-ci. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

