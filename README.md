# IsEmail

IsEmail is a no-nonsense approach for checking whether that user-supplied email address could be real. Sick of not being able to use [email address tagging](http://en.wikipedia.org/wiki/Email_address#Address_tags) to sort through your [Bacn](https://en.wiktionary.org/wiki/bacn)? We can fix that.

Regular expressions are cheap to write, but often require maintenance when new top-level domains come out or don't conform to email addressing features that come back into vogue. IsEmail allows you to validate an email address — and even check the domain, if you wish — with one simple call, making your code more readable and faster to write. When you want to know why an email address doesn't validate, we even provide you with a diagnosis.

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add is_email

If you are not using Bundler to manage dependencies, install the gem by executing:

    $ gem install is_email

## Usage

For the simplest usage, import and use the `IsEmail.email?` module method:

```ruby
address = "test@example.com"
bool_result = IsEmail.email?(address)
detailed_result = IsEmail.email?(address, diagnose: true)
```

## Contributing

So you're interested in contributing to IsEmail? Check out our [contributing guidelines](CONTRIBUTING.md) for more information on how to do that.

## Supported Ruby Versions

This library aims to support and is [tested against](https://github.com/michaelherold/is_email/actions) the following Ruby versions:

* Ruby 3.0
* Ruby 3.1
* Ruby 3.2

If something doesn't work on one of these versions, it's a bug.

This library may inadvertently work (or seem to work) on other Ruby versions, however we will only provide support for the versions listed above.

If you would like this library to support another Ruby version or implementation, you may volunteer to be a maintainer. Being a maintainer entails making sure all tests run and pass on that implementation. When something breaks on your implementation, you will be responsible for providing patches in a timely fashion. If critical issues for a particular implementation exist at the time of a major release, we may drop support for that Ruby version.

## Versioning

This library aims to adhere to [Semantic Versioning 2.0.0](http://semver.org/spec/v2.0.0.html). Report violations of this scheme should as bugs. Specifically, if a minor or patch version breaks backward compatibility, that version should be immediately yanked and/or a new version should be immediately released that restores compatibility. Only new major versions will introduce breaking changes to the public API. As a result of this policy, you can (and should) specify a dependency on this gem using the [pessimistic version constraint](http://guides.rubygems.org/patterns/#pessimistic-version-constraint) with two digits of precision. For example:

    spec.add_dependency "is_email", "~> 0.1"

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

We expect everyone interacting in the IsEmail project's codebases, issue trackers, chat rooms and mailing lists to follow the [code of conduct](https://github.com/michaelherold/is_email/blob/main/CODE_OF_CONDUCT.md).

## Acknowledgments

I based the base `Validators::Parser` off [Dominic Sayers](https://github.com/dominicsayers)'s [is_email script](https://github.com/dominicsayers/isemail). I wanted the functionality in Python, so I ported it from the original PHP. I later ported it to Ruby since it's handy to have there too.
