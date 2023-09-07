# DelayedJobPreventDuplicate

The purpose of this gem is to prevent to re-enqueue on DelayedJob a task already enqueued.  
So we set a "signature" attached to every task enqueued which is a composite from the class and the id of the object, and the method called.  
And then when creating a new job we look in the "pending" jobs if there is another one with the same signature (not in the "working" one because a task can be executed and yet you want to re-excute it because of any change). 

## Note

This gem is based based on the [synth](synth) work: (https://gist.github.com/synth/fba7baeffd083a931184)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'delayed_job_prevent_duplicate'
```

This line should be added after including the gem 'delayed_job'

And then execute:

    $ bundle install

Next, you need to run the generator: 

```ruby
rails g delayed_job_prevent_duplicate
```
  
All should be fine now!  


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/noesya/delayed_job_prevent_duplicate.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Bibliography

(https://groups.google.com/g/delayed_job/c/gZ9bFCdZrsk#2a05c39a192e630c)
(https://github.com/collectiveidea/delayed_job/blob/master/lib/delayed/backend/base.rb)
(https://github.com/ignatiusreza/activejob-trackable)