require "rails/html/owasp/sanitizer/version"

if defined?(RUBY_ENGINE) && RUBY_ENGINE == "jruby"
  require "rails-html-sanitizer"
  require "rails/html/owasp/sanitizer"

  module Rails
    module Html
      class Sanitizer
        class << self
          def full_sanitizer
            ::Rails::Html::Owasp::FullSanitizer
          end

          def link_sanitizer
            ::Rails::Html::Owasp::LinkSanitizer
          end

          def white_list_sanitizer
            ::Rails::Html::Owasp::WhiteListSanitizer
          end
        end
      end
    end
  end
end

