require 'htmlentities'
require 'rails/html/owasp/whitelist'

require 'guava-11.0.2.jar'
require 'owasp-java-html-sanitizer-r239.jar'

java_import 'org.owasp.html.HtmlPolicyBuilder'
java_import 'org.owasp.html.Sanitizers'

module Rails
  module Html
    module Owasp

      class Sanitizer

        def sanitize(html, options = {})
          return html if html.nil? || html.empty?
          policy(options).to_factory.sanitize html
        end

        private

        # returns a filtering policy that strips out all tags and encodes any
        # entities.
        #
        # override in subclasses to specify exceptions
        def policy(options = {})
          HtmlPolicyBuilder.new
        end

      end

      # == FullSanitizer
      #
      # Strips all tags, leaving only plain text.
      #
      # === Sanitize Options
      #
      # Pass +encode_special_chars: false+ to not have special chars encoded to
      # HTML entities.
      class FullSanitizer < Sanitizer

        def sanitize(html, options = {})
          result = super
          if false == options[:encode_special_chars]
            # doesn't appear to be possible to turn off the encoding at the
            # owasp library level, so we roll it back here
            result = HTMLEntities.new.decode result
          end
          result
        end

      end

      # == WhiteListSanitizer
      #
      # Sanitizes HTML based on whitelists for html elements and attributes.
      #
      # === Sanitize Options
      #
      # Use the +tags+ and +attributes+ options to override the default
      # whitelists which are defined in +Owasp::Whitelist::ALLOWED_ELEMENTS+
      # and +Owasp::Whitelist::ALLOWED_ATTRIBUTES+.
      #
      # Pass +add_rel_nofollow: true+ to enforce rel="nofollow" on links.
      #
      # Pass +skip_empty_tags_if_useless: true+ to remove tags that have no
      # attributes (after sanitization) and will render nothing in this state,
      # i.e. +<img>+ or +<a>+.
      #
      # By default, +style+ attributes are allowed and have their content
      # sanitized. Pass +allow_styling: false+ to have any +style+ attributes
      # removed.
      class WhiteListSanitizer < FullSanitizer
        class << self
          attr_accessor :allowed_tags
          attr_accessor :allowed_attributes
        end

        def sanitize_css(style_string)
          styling_policy.sanitize_css_properties(style_string).to_s
        end

        private

        def policy(options = {})
          options = {
            tags: (self.class.allowed_tags || Whitelist::ALLOWED_ELEMENTS),
            attributes: (self.class.allowed_attributes || Whitelist::ALLOWED_ATTRIBUTES),
            add_rel_nofollow: false,
            skip_empty_tags_if_useless: false,
            allow_styling: true
          }.merge options

          raise ArgumentError, 'tags must be enumerable' unless Enumerable === options[:tags]
          raise ArgumentError, 'attributes must be enumerable' unless Enumerable === options[:attributes]

          super(options).
            allow_elements( *options[:tags] ).
            allow_attributes( *options[:attributes] ).globally.
            allow_standard_url_protocols.
            tap do |policy|
              policy.allow_styling if options[:allow_styling]
              policy.allow_without_attributes( *HtmlPolicyBuilder::DEFAULT_SKIP_IF_EMPTY ) unless options[:skip_empty_tags_if_useless]
              policy.require_rel_nofollow if options[:add_rel_nofollow]
            end
        end

        def styling_policy
          # break some privacy to get hold of a StylingPolicy instance
          constructor = Java::OrgOwaspHtml::StylingPolicy.
            java_class.declared_constructors.first
          constructor.accessible = true
          constructor.new_instance(Java::OrgOwaspHtml::CssSchema::DEFAULT).to_java
        end
      end

      # a WhiteListSanitizer, but without allowing links
      class LinkSanitizer < WhiteListSanitizer
        private

        def policy(options = {})
          super(options).disallowElements('a')
        end
      end

    end
  end
end

