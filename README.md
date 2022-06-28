
# Ruby::Miradore: Working with the Miradore MDM API
[![Gem Version](https://badge.fury.io/rb/ruby-miradore.svg)](https://badge.fury.io/rb/ruby-miradore)

This gem implements both Miradore API's v1 to search and perform some CRUD oprations on devices as well as users, and the v2 where allows to perform some actions against devices such as lock,wipe or activate lost mode on mobile devices.

The v1 of the API is returning XML format so this gem will transform from XML to an open struct. Same happens with the v2, even though returns a json message, it will be transformed to an open struct as well.

#### Miradore v1 specification
https://www.miradore.com/wp-content/uploads/2014/07/api-specification-113.pdf

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ruby-miradore'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install ruby-miradore

## Usage

#### Search devices using API v1

    _device = Ruby::Miradore::Device.new(subdomain: 'test',auth:'auth_token').all(
      attribute: 'InvDevice,InvUser',
      filter: [
            { field: 'InvDevice.SerialNumber', operator: :eq, value: 'serial_number' },
            { field: :or },
            { field: 'ID', operator: :eq, value: 12 }
        ],
      options: { rows: 500 }
    )

It requires firsts to specify the subdomain in miradore as well as the Auth token to be able to access the invnetory in miradore.
Specifying `attributes` the call will only return data from those attributs and ingnore the rest, but if no `attribute` was defined it will return the default `*`data.

`filter` is an array of conditions and every condition has a `field` and `operator` and finally a `value`. For instance in the example avobe, the call will look devices where either the searial number or the internal id matches the specified `value`

#### Using API v2 to lock a device

Now, let's assume that the previous call using the v1 API, it gets one device that it's been assigned to `_device` variable.
If now we want to perform a lock action over that device, we just need to call the lock method as such:

    _device.lock
 
This will automatically call the proper endpoint as part of the v2 API to lock the device remotely.
Other actions implemented directly are, `wipe` `lostmode` `reboot` `location` `retire` the outcome of those actions will depend on the device, for instance all of them will work on mobile devices but `location` or `lostmode` may not work on some laptop or desktop devices.

As we mentioned earlier this gem will allow you to call any endpoint from v1 as well as v2 Miradore API, if you need any other action not provided in this documentation, please inspect the code or contact me for more details.

Please feel free to fork or contribute to this gem in any way you like, you'll be very welmcome!
 
### Help

[email the developers](mailto:edugarcas@gmail.com)

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/ruby-miradore. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/ruby-miradore/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Ruby::Miradore project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/ruby-miradore/blob/master/CODE_OF_CONDUCT.md).
