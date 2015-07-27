# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rails/html/owasp/sanitizer/version'

Gem::Specification.new do |spec|
  spec.name          = "rails-html-sanitizer-jruby"
  spec.version       = Rails::Html::Owasp::Sanitizer::VERSION
  spec.authors       = ["Jens Kraemer"]
  spec.email         = ["jk@jkraemer.net"]
  spec.description   = %q{HTML sanitization for JRuby/Rails applications}
  spec.summary       = %q{This gem provides HTML fragment sanitization for Rails applications running on JRuby. It is a wrapper around the OWASP Java HTML Sanitizer library (https://www.owasp.org/index.php/OWASP_Java_HTML_Sanitizer_Project).}
  spec.homepage      = "https://github.com/jkraemer/rails-html-sanitizer-jruby"
  spec.license       = "MIT"

  spec.files         = Dir["lib/**/*", "README.md", "LICENSE*", "CHANGELOG.md"]
  spec.test_files    = Dir["test/**/*"]
  spec.require_paths = ["lib"]

  spec.add_dependency "rails-html-sanitizer", "~> 1.0"
  spec.add_dependency "htmlentities", "~> 4.3"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "minitest"
end
