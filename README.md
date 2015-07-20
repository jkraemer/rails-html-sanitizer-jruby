# Rails Html Sanitizers for JRuby

## Motivation

In Rails 4.2 and above the
[rails-html-sanitizer](https://github.com/rails/rails-html-sanitizer) gem will
be responsible for sanitizing HTML fragments in Rails applications, i.e. in the
`sanitize`, `sanitize_css`, `strip_tags` and `strip_links` methods. This gem is
based on Loofah, which in turn uses Nokogiri to do the XML/HTML processing.

While Nokogiri aims to provide a native Java implementation that is equivalent
to its MRI C extension, Loofah manages to expose quite lot of differences
between the two (most of them looking like bugs of the Java implementation),
resulting in [a lot](https://travis-ci.org/flavorjones/loofah/jobs/61361820) of [failing
tests](https://github.com/flavorjones/loofah/issues/88) when running on JRuby.

Since fixing Nokogiri on JRuby so the Loofah test suite passes does not seem to
happen anytime soon (the amount of test failures is pretty massive, and
Nokogiri's Java code base isn't exactly easy to read and understand), the goal
of this gem is to provide reliable HTML sanitization for JRuby Rails apps that
is _not_ based on Nokogiri.

The [OWASP Java HTML Sanitizer
Project](https://www.owasp.org/index.php/OWASP_Java_HTML_Sanitizer_Project)
turns out to do exactly what we need, and as far as I can tell it's quite well
tested.

This gem wraps that OWASP sanitizer in a Rails::Html::Sanitizer compatible API.
Its test suite is based on the [Sanitizer
tests](https://github.com/rails/rails-html-sanitizer/blob/master/test/sanitizer_test.rb) from the same project. The cases tested are the same, but since there are many ways to sanitize a given input, I had to adapt the expected output here and there. Mostly this was necessary because the OWASP sanitizer tends to escape characters like `&`, `=`, `'` and `"` more often than Loofah, and it is more strict when it comes to correcting syntactically wrong HTML. Also the white list for allowed inline styles seems to be a bit stricter.


## Installation

Add this line to your application's Gemfile:

    gem 'rails-html-sanitizer-jruby', platforms: :jruby

And then execute:

    $ bundle

If your app is running on JRuby, the gem will overwrite the
`Rails::Html::Sanitizer::*_sanitizer` class methods to return the corresponding
OWASP based Sanitizer implementations instead. Otherwise, the gem does nothing
(so you can also add it to your Gemfile without the `platforms`
option and still run on non-JRuby platforms).

## Usage

If you are using the default sanitization helpers of Rails 4.2 or above,
there's nothing more to do as these will automatically use the new sanitizers.

Read on for custom use of the various sanitizers.

### Sanitizers

All sanitizers respond to `sanitize` just as the default sanitizers do.

Sanitized output will differ in some cases, mostly because the owasp lib seems
to escape more where Loofah just strips things away. So expect some more `&lt;`
and other entities to survive. The test suite is based on the
rails-html-sanitizer test suite, amended for those slight differences in
output.


#### FullSanitizer

```ruby
full_sanitizer = Rails::Html::Owasp::FullSanitizer.new
full_sanitizer.sanitize("<b>Bold</b> no more!  <a href='more.html'>See more here</a>...")
# => Bold no more!  See more here...
```

#### LinkSanitizer

```ruby
link_sanitizer = Rails::Html::Owasp::LinkSanitizer.new
link_sanitizer.sanitize('<a href="example.com">Only the link text will be kept.</a>')
# => Only the link text will be kept.
```

#### WhiteListSanitizer

```ruby
white_list_sanitizer = Rails::Html::Owasp::WhiteListSanitizer.new

# sanitize via an extensive white list of allowed elements
white_list_sanitizer.sanitize(@article.body)

# white list only the supplied tags and attributes
white_list_sanitizer.sanitize(@article.body, tags: %w(table tr td), attributes: %w(id class style))

# white list sanitizer can also sanitize css
white_list_sanitizer.sanitize_css('background-color: #000;')
```

### Scrubbers / Customizing

Support for custom scrubbers as introduced by the rails-html-sanitizer gem is
not implemented at the moment. If you want to customize sanitization, subclass
one of the Owasp sanitizers and override the policy method. The
[Javadocs](https://rawgit.com/OWASP/java-html-sanitizer/master/distrib/javadoc/index.html)
will come in handy in this case.


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

