# YouShallNotPass
[![Build Status](https://travis-ci.org/iachettifederico/you_shall_not_pass.png?branch=master)](https://travis-ci.org/iachettifederico/you_shall_not_pass)


Simple framework-agnostic authorization library.

## Usage

You Shall Not Pass is a very minimalistic authorization framework. It doesn't really care about your system architecture.
You don't really need to set up your authentication schema in any particular way (in fact, you don't even really need authentication to make You Shall Not Pass work).

The first you need is to create an Authorizator. You can define one by extending `YouShallNotPass::Authorizator` and then define the authorization policies.

Let's write a first example:

```ruby
class MyAuthorizator < YouShallNotPass::Authorizator
  def time_policies
    {
      morning_shift: Time.now.hour <= 12,
      afternoon_shift: Time.now.hour > 12 && Time.now.hour < 20,
      night_shift: Time.now.hour >= 20,
    }
  end
end
```

As you can see, there's no user, role, or any kind of authentication going on in this example.

Now we can ask if we have permission to `<insert action here>` depending on the shift:

```ruby
Time.now
# => 2015-02-09 20:17:26 -0300

Time.now.hour
# => 20

auth = MyAuthorizator.new
auth.can?(:morning_shift)
# => false

auth.can?(:afternoon_shift)
# => false

auth.can?(:night_shift)
# => true
```

In this case, the code was run at 20:17, so it corresponds to the night shift.

We can also perform an action depending on the shift. So let's get some output:

```ruby
auth.perform_for(:morning_shift) do
  puts "Morning shift"
end

auth.perform_for(:afternoon_shift) do
  puts "Afternoon shift"
end

auth.perform_for(:night_shift) do
  puts "Night shift"
end

# >> Night shift
```

And as we are on the night shift, the only block that get's called is the one that performs for the night shift.

## *_policies

You Shall Not Pass allows you to group your permissions by providing instance methods suffixed with `_policies`.

So, if we have:

```ruby
class MyAuthorizator < YouShallNotPass::Authorizator
  def time_policies
    {
      morning_shift: Time.now.hour <= 12,
      afternoon_shift: Time.now.hour > 12 && Time.now.hour < 20,
      night_shift: Time.now.hour >= 20,
    }
  end
  
  def date_policies
    {
      jan: Time.now.month == 1,
      feb: Time.now.month == 2,
    }
  end
end
```

The available policy names are:

```ruby
auth = MyAuthorizator.new
auth.policies.keys
# => [:morning_shift, :afternoon_shift, :night_shift, :jan, :feb]
```

## Attributes

If you have an authorization schema in place, you can make You Shall Not Pass aware of it by introducing attributes.

Let's say we have a `User` object and we want our authenticator to use it. We can extend `MyAuthorizator` to accept a `user` attribute and use it on the policies.

```ruby
class User
  def initialize(admin)
    @admin = admin
  end
  
  def admin?
    @admin
  end
end

class MyAuthorizator < YouShallNotPass::Authorizator
  attribute :user

  def user_policies
    {
      admin: user.admin? 
    }
  end
end
```

Now we need to instantiate an authorizator passing the user as a (named) parameter:

```ruby
auth1 = MyAuthorizator.new(user: User.new(true))
auth1.perform_for(:admin) do
  puts "First user"
end

auth2 = MyAuthorizator.new(user: User.new(false))
auth2.perform_for(:admin) do
  puts "Second user"
end

# >> First user
```

And only the first one will print.

You can add as many attributes as you want and you will get an instance method to use it at will.

It's important to notice that the `user` in this case is just a Ruby object. You don't need to comply with any API in particular.

In a web framework, is a good idea to create the authorizator after defining the current user and then pass the current user as a parameter.

If you need to authenticate using other objects, you can keep adding attributes to the authorizator (for example pass a settings array, the environment your on - dev, prod-, etc).


## Installation

Add this line to your application's Gemfile:

```ruby
  gem 'you_shall_not_pass'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install you_shall_not_pass


## Contributing

1. Fork it ( https://github.com/[my-github-username]/you_shall_not_pass/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
