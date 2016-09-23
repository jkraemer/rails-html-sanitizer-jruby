require "minitest/autorun"
require "rails-html-sanitizer-jruby"
require 'benchmark'

class SanitizersTest < Minitest::Test

  def test_strip_tags_with_quote
    input = '<" <img src="trollface.gif" onload="alert(1)"> hi'
    assert_equal '&lt;&#34;  hi', full_sanitize(input)
  end

  def test_strip_invalid_html
    assert_equal "&lt;&lt;", full_sanitize("<<<bad html")
  end

  def test_strip_nested_tags
    expected = "Wei&lt;a onclick&#61;&#39;alert(document.cookie);&#39;/&gt;rdos"
    input = "Wei<<a>a onclick='alert(document.cookie);'</a>/>rdos"
    assert_equal expected, full_sanitize(input)
  end

  def test_strip_tags_multiline
    expected = %{This is a test.\n\n\n\nIt no longer contains any HTML.\n}
    input = %{<title>Anything <em>in</em> a title tag is removed.</title><p>This is <b>a <a href="" target="_blank">test</a></b>.</p>\n\n<!-- it has a comment -->\n\n<p>It no <b>longer <strong>contains <em>any <strike>HTML</strike></em>.</strong></b></p>\n}
    assert_equal expected, full_sanitize(input)
  end

  # part of rails-html-sanitizer tests, which strip everything after <--.
  # escaping the < should be ok as well.
  def test_strip_comments
    assert_equal "This is &lt;-- not\n a comment here.",
      full_sanitize("This is <-- not\n a comment here.")
  end
  def test_should_strip_unclosed_comments
    assert_equal "This is ", full_sanitize("This is <!-- a\n comment here.")
  end
  def test_should_strip_comments
    assert_equal "This is ", full_sanitize("This is <!-- a\n comment here. -->")
  end

  def test_strip_cdata
    assert_equal "This has a ]]&gt; here.", full_sanitize("This has a <![CDATA[<section>]]> here.")
  end

  def test_strip_unclosed_cdata
    assert_equal "This has an unclosed ]] here...", full_sanitize("This has an unclosed <![CDATA[<section>]] here...")
  end

  def test_strip_blank_string
    [nil, '', '   '].each { |blank| assert_equal blank, full_sanitize(blank) }
  end

  def test_strip_tags_with_plaintext
    assert_equal "Dont touch me", full_sanitize("Dont touch me")
  end

  def test_strip_tags_with_tags
    assert_equal "This is a test.", full_sanitize("<p>This <u>is<u> a <a href='test.html'><strong>test</strong></a>.</p>")
  end

  def test_strip_tags_with_many_open_quotes
    assert_equal "&lt;&lt;", full_sanitize("<<<bad html>")
  end

  def test_strip_tags_with_sentence
    assert_equal "This is a test.", full_sanitize("This is a test.")
  end

  def test_strip_tags_with_comment
    assert_equal "This has a  here.", full_sanitize("This has a <!-- comment --> here.")
  end

  def test_strip_tags_with_frozen_string
    assert_equal "Frozen string with no tags", full_sanitize("Frozen string with no tags".freeze)
  end

  def test_full_sanitize_allows_turning_off_encoding_special_chars
    assert_equal '&amp;', full_sanitize('&')
    assert_equal '&', full_sanitize('&', encode_special_chars: false)
  end

  def test_strip_links_with_tags_in_tags
    expected = "&lt;a href&#61;&#39;hello&#39;&gt;all <b>day</b> long&lt;/a&gt;"
    input = "<<a>a href='hello'>all <b>day</b> long<</A>/a>"
    assert_equal expected, link_sanitize(input)
  end

  def test_strip_links_with_unclosed_tags
    assert_equal "", link_sanitize("<a<a")
  end

  def test_strip_links_with_plaintext
    assert_equal "Dont touch me", link_sanitize("Dont touch me")
  end

  def test_strip_links_with_line_feed_and_uppercase_tag
    assert_equal "on my mind\nall day long", link_sanitize("<a href='almost'>on my mind</a>\n<A href='almost'>all day long</A>")
  end

  def test_strip_links_leaves_nonlink_tags
    assert_equal "My mind\nall <b>day</b> long", link_sanitize("<a href='almost'>My mind</a>\n<A href='almost'>all <b>day</b> long</A>")
  end

  def test_strip_links_with_links
    assert_equal "0wn3d", link_sanitize("<a href='http://www.rubyonrails.com/'><a href='http://www.rubyonrails.com/' onlclick='steal()'>0wn3d</a></a>")
  end

  def test_strip_links_with_linkception
    assert_equal "Magic", link_sanitize("<a href='http://www.rubyonrails.com/'>Mag<a href='http://www.ruby-lang.org/'>ic")
  end

  def test_strip_links_with_a_tag_in_href
    assert_equal "FrrFox", link_sanitize("<href onlclick='steal()'>FrrFox</a></href>")
  end

  def test_sanitize_form
    assert_sanitized "<form action=\"/foo/bar\" method=\"post\"><input></form>", ''
  end

  def test_sanitize_plaintext
    assert_sanitized "<plaintext><span>foo</span></plaintext>", "&lt;span&gt;foo&lt;/span&gt;&lt;/plaintext&gt;"
  end

  def test_sanitize_script
    assert_sanitized "a b c<script language=\"Javascript\">blah blah blah</script>d e f", "a b cd e f"
  end

  def test_sanitize_js_handlers
    raw = %{onthis="do that" <a href="#" onclick="hello" name="foo" onbogus="remove me">hello</a>}
    assert_sanitized raw, %{onthis&#61;&#34;do that&#34; <a href="#" name="foo">hello</a>}
  end

  def test_sanitize_javascript_href
    raw = %{href="javascript:bang" <a href="javascript:bang" name="hello">foo</a>, <span href="javascript:bang">bar</span>}
    assert_sanitized raw, %{href&#61;&#34;javascript:bang&#34; <a name="hello">foo</a>, <span>bar</span>}
  end

  def test_sanitize_image_src
    raw = %{src="javascript:bang" <img src="javascript:bang" width="5">foo</img>, <span src="javascript:bang">bar</span>}
    assert_sanitized raw, %{src&#61;&#34;javascript:bang&#34; <img width="5" />foo, <span>bar</span>}
  end

  always_stripped = %w( form input select command meta link embed param )
  always_stripped.each do |tag_name|
    define_method "test_should_strip_#{tag_name}_tag" do
      assert_sanitized "start <#{tag_name} title=\"1\" onclick=\"foo\">foo <bad>bar</bad> baz</#{tag_name}> end", %(start foo bar baz end)
    end
  end

  # these tags are auto-closed by the sanitizer before the originally
  # enclosed text since they do not allow text content
  strict_content_tags = %w( audio colgroup dir hr table tbody thead tfoot video )
  strict_content_tags.each do |tag_name|
    define_method "test_should_allow_#{tag_name}_tag" do
      assert_sanitized "start <#{tag_name} title=\"1\" onclick=\"foo\">foo <bad>bar</bad> baz</#{tag_name}> end", %(start <#{tag_name} title="1"></#{tag_name}>foo bar baz end)
    end
  end

  # these tags are auto-closed by the sanitizer before the originally
  # enclosed text since they do not allow any content
  no_content_tags = %w( area br col hr img )
  no_content_tags.each do |tag_name|
    define_method "test_should_allow_#{tag_name}_tag" do
      assert_sanitized "start <#{tag_name} title=\"1\" onclick=\"foo\">foo <bad>bar</bad> baz</#{tag_name}> end", %(start <#{tag_name} title="1" />foo bar baz end)
    end
  end

  content_tags = Rails::Html::Owasp::Whitelist::ALLOWED_ELEMENTS -
    strict_content_tags -
    no_content_tags -
    %w(ol ul dl tr)
  content_tags.each do |tag_name|
    define_method "test_should_allow_#{tag_name}_tag" do
      assert_sanitized "start <#{tag_name} title=\"1\" onclick=\"foo\">foo <bad>bar</bad> baz</#{tag_name}> end", %(start <#{tag_name} title="1">foo bar baz</#{tag_name}> end)
    end
  end

  def test_should_strip_textarea
    assert_sanitized "start <textarea title=\"1\" onclick=\"foo\">foo <bad>bar</bad> baz</textarea> end", %(start foo &lt;bad&gt;bar&lt;/bad&gt; baz end)
  end

  def test_should_allow_dl_tag
    assert_sanitized "start <dl title=\"1\" onclick=\"foo\">foo <bad>bar</bad> baz</dl> end", %(start <dl title="1"><dd>foo bar baz</dd></dl> end)
  end

  def test_should_allow_ol_tag
    assert_sanitized "start <ol title=\"1\" onclick=\"foo\">foo <bad>bar</bad> baz</ol> end", %(start <ol title="1"><li>foo bar baz</li></ol> end)
  end

  def test_should_allow_ul_tag
    assert_sanitized "start <ul title=\"1\" onclick=\"foo\">foo <bad>bar</bad> baz</ul> end", %(start <ul title="1"><li>foo bar baz</li></ul> end)
  end

  def test_should_allow_tr_tag
    assert_sanitized "start <tr title=\"1\" onclick=\"foo\">foo <bad>bar</bad> baz</tr> end", %(start <tr title="1"><td>foo bar baz end</td></tr>)
  end


  def test_should_allow_anchors
    assert_sanitized %(<a href="foo" onclick="bar"><script>baz</script></a>), %(<a href=\"foo\"></a>)
  end

  def test_video_poster_sanitization
    assert_sanitized %(<video src="videofile.ogg" autoplay  poster="posterimage.jpg"></video>), %(<video src="videofile.ogg" poster="posterimage.jpg"></video>)
    assert_sanitized %(<video src="videofile.ogg" poster=javascript:alert(1)></video>), %(<video src="videofile.ogg"></video>)
  end

  # RFC 3986, sec 4.2
  def test_allow_colons_in_path_component
    assert_sanitized "<a href=\"./this:that\">foo</a>"
  end

  %w(src width height alt).each do |img_attr|
    define_method "test_should_allow_image_#{img_attr}_attribute" do
      assert_sanitized %(<img #{img_attr}="foo" onclick="bar" />), %(<img #{img_attr}="foo" />)
    end
  end

  def test_should_handle_non_html
    assert_sanitized 'abc'
  end

  def test_should_handle_blank_text
    [nil, '', '   '].each { |blank| assert_sanitized blank }
  end

  def test_setting_allowed_tags_affects_sanitization
    scope_allowed_tags %w(u) do |sanitizer|
      assert_equal '<u></u>', sanitizer.sanitize('<a><u></u></a>')
    end
  end

  def test_setting_allowed_attributes_affects_sanitization
    scope_allowed_attributes %w(foo) do |sanitizer|
      input = '<a foo="hello" bar="world"></a>'
      assert_equal '<a foo="hello"></a>', sanitizer.sanitize(input)
    end
  end

  def test_custom_tags_overrides_allowed_tags
    scope_allowed_tags %(u) do |sanitizer|
      input = '<a><u></u></a>'
      assert_equal '<a></a>', sanitizer.sanitize(input, tags: %w(a))
    end
  end

  def test_custom_attributes_overrides_allowed_attributes
    scope_allowed_attributes %(foo) do |sanitizer|
      input = '<a foo="hello" bar="world"></a>'
      assert_equal '<a bar="world"></a>', sanitizer.sanitize(input, attributes: %w(bar))
    end
  end

  def test_should_allow_custom_tags
    text = "<u>foo</u>"
    assert_equal text, white_list_sanitize(text, tags: %w(u))
  end

  def test_should_allow_only_custom_tags
    text = "<u>foo</u> with <i>bar</i>"
    assert_equal "<u>foo</u> with bar", white_list_sanitize(text, tags: %w(u))
  end

  def test_should_allow_url_in_cite_attribute
    text = %(<blockquote cite="http://example.com/">foo</blockquote>)
    assert_equal text, white_list_sanitize(text)
  end

  def test_should_allow_custom_tags_with_attributes
    text = %(<baz title="bar">foo</baz>)
    assert_equal text, white_list_sanitize(text, tags: %w(baz))
  end

  def test_should_allow_custom_tags_with_custom_attributes
    text = %(<baz foo="bar">Lorem ipsum</baz>)
    assert_equal text, white_list_sanitize(text, tags: ['baz'], attributes: ['foo'])
  end

  def test_scrub_style_if_style_attribute_option_is_passed
    input = '<p style="color: #000; background-image: url(http://www.ragingplatypus.com/i/cam-full.jpg);"></p>'
    assert_equal '<p style="color:#000"></p>', white_list_sanitize(input, attributes: %w(style))
  end

  def test_should_raise_argument_error_if_tags_is_not_enumerable
    assert_raises ArgumentError do
      white_list_sanitize('<a>some html</a>', tags: 'foo')
    end
  end

  def test_should_raise_argument_error_if_attributes_is_not_enumerable
    assert_raises ArgumentError do
      white_list_sanitize('<a>some html</a>', attributes: 'foo')
    end
  end

  def test_should_strip_href_attribute_in_a_with_bad_protocols
    assert_sanitized %(<a href="javascript:bang" title="1">boo</a>), %(<a title="1">boo</a>)
  end

  def test_should_strip_src__attribute_in_img_with_bad_protocols
      assert_sanitized %(<img src="javascript:bang" title="1">boo</img>), %(<img title="1" />boo)
      assert_sanitized %(<img src="javascript:bang" title="1" />), %(<img title="1" />)
    end

  def test_should_block_script_tag
    assert_sanitized %(<SCRIPT\nSRC=http://ha.ckers.org/xss.js></SCRIPT>), ""
  end

  def test_should_not_fall_for_xss_image_hack_with_uppercase_tags
    assert_sanitized %(<IMG """><SCRIPT>alert("XSS")</SCRIPT>">), "<img />&#34;&gt;"
  end

  [%(<IMG SRC="javascript:alert('XSS');">),
   %(<IMG SRC=javascript:alert('XSS')>),
   %(<IMG SRC=JaVaScRiPt:alert('XSS')>),
   %(<IMG SRC=javascript:alert(&quot;XSS&quot;)>),
   %(<IMG SRC=javascript:alert(String.fromCharCode(88,83,83))>),
   %(<IMG SRC=&#106;&#97;&#118;&#97;&#115;&#99;&#114;&#105;&#112;&#116;&#58;&#97;&#108;&#101;&#114;&#116;&#40;&#39;&#88;&#83;&#83;&#39;&#41;>),
   %(<IMG SRC=&#0000106&#0000097&#0000118&#0000097&#0000115&#0000099&#0000114&#0000105&#0000112&#0000116&#0000058&#0000097&#0000108&#0000101&#0000114&#0000116&#0000040&#0000039&#0000088&#0000083&#0000083&#0000039&#0000041>),
   %(<IMG SRC=&#x6A&#x61&#x76&#x61&#x73&#x63&#x72&#x69&#x70&#x74&#x3A&#x61&#x6C&#x65&#x72&#x74&#x28&#x27&#x58&#x53&#x53&#x27&#x29>),
   %(<IMG SRC="jav\tascript:alert('XSS');">),
   %(<IMG SRC="jav&#x09;ascript:alert('XSS');">),
   %(<IMG SRC="jav&#x0A;ascript:alert('XSS');">),
   %(<IMG SRC="jav&#x0D;ascript:alert('XSS');">),
   %(<IMG SRC=" &#14;  javascript:alert('XSS');">),
   %(<IMG SRC="javascript&#x3a;alert('XSS');">),
   %(<IMG SRC=`javascript:alert("RSnake says, 'XSS'")`>)].each_with_index do |img_hack, i|
    define_method "test_should_not_fall_for_xss_image_hack_#{i+1}" do
      assert_sanitized img_hack, "<img />"
    end
  end

  def test_should_sanitize_tag_broken_up_by_null
    assert_sanitized %(<SCR\0IPT>alert(\"XSS\")</SCR\0IPT>), "alert(&#34;XSS&#34;)"
  end

  def test_should_sanitize_invalid_script_tag
    assert_sanitized %(<SCRIPT/XSS SRC="http://ha.ckers.org/xss.js"></SCRIPT>), ""
  end

  def test_should_sanitize_script_tag_with_multiple_open_brackets
    assert_sanitized %(<<SCRIPT>alert("XSS");//<</SCRIPT>), "&lt;"
    assert_sanitized %(<iframe src=http://ha.ckers.org/scriptlet.html\n<a), ""
  end

  def test_should_sanitize_unclosed_script
    assert_sanitized %(<SCRIPT SRC=http://ha.ckers.org/xss.js?<B>), ""
  end

  def test_should_sanitize_half_open_scripts
    assert_sanitized %(<IMG SRC="javascript:alert('XSS')"), "<img />"
  end

  def test_should_not_fall_for_ridiculous_hack
    img_hack = %(<IMG\nSRC\n=\n"\nj\na\nv\na\ns\nc\nr\ni\np\nt\n:\na\nl\ne\nr\nt\n(\n'\nX\nS\nS\n'\n)\n"\n>)
    assert_sanitized img_hack, "<img />"
  end

  def test_should_sanitize_attributes
    assert_sanitized %(<SPAN title="'><script>alert()</script>">blah</SPAN>), %(<span title="&#39;&gt;&lt;script&gt;alert()&lt;/script&gt;">blah</span>)
  end

  def test_should_sanitize_illegal_style_properties
    raw      = %(display:block; position:absolute; left:0; top:0; width:100%; height:100%; z-index:1; background-color:black; background-image:url(http://www.ragingplatypus.com/i/cam-full.jpg); background-x:center; background-y:center; background-repeat:repeat;)
    expected = %(width:100%;height:100%;background-color:black;background-repeat:repeat)
    assert_equal expected, sanitize_css(raw)
  end

  def test_should_sanitize_with_trailing_space
    raw = "width:100%; "
    expected = "width:100%"
    assert_equal expected, sanitize_css(raw)
  end

  def test_should_sanitize_xul_style_attributes
    raw = %(-moz-binding:url('http://ha.ckers.org/xssmoz.xml#xss'))
    assert_equal '', sanitize_css(raw)
  end

  def test_should_sanitize_invalid_tag_names
    assert_sanitized(%(a b c<script/XSS src="http://ha.ckers.org/xss.js"></script>d e f), "a b cd e f")
  end

  def test_should_sanitize_non_alpha_and_non_digit_characters_in_tags
    assert_sanitized('<a onclick!#$%&()*~+-_.,:;?@[/|\]^`=alert("XSS")>foo</a>', "<a>foo</a>")
  end

  def test_should_sanitize_invalid_tag_names_in_single_tags
    assert_sanitized('<img/src="http://ha.ckers.org/xss.js"/>', '<img src="http://ha.ckers.org/xss.js" />')
  end

  def test_should_sanitize_img_dynsrc_lowsrc
    assert_sanitized(%(<img lowsrc="javascript:alert('XSS')" />), "<img />")
  end

  def test_should_sanitize_div_background_image_unicode_encoded
    raw = %(background-image:\0075\0072\006C\0028'\006a\0061\0076\0061\0073\0063\0072\0069\0070\0074\003a\0061\006c\0065\0072\0074\0028.1027\0058.1053\0053\0027\0029'\0029)
    assert_equal '', sanitize_css(raw)
  end

  def test_should_sanitize_div_style_expression
    raw = %(width: expression(alert('XSS'));)
    assert_equal '', sanitize_css(raw)
  end

  def test_should_sanitize_across_newlines
    raw = %(\nwidth:\nexpression(alert('XSS'));\n)
    assert_equal '', sanitize_css(raw)
  end

  def test_should_sanitize_img_vbscript
    assert_sanitized %(<img src='vbscript:msgbox("XSS")' />), '<img />'
  end

  def test_should_sanitize_cdata_section
    assert_sanitized "<![CDATA[<span>section</span>]]>", "section]]&gt;"
  end

  def test_should_sanitize_unterminated_cdata_section
    assert_sanitized "<![CDATA[<span>neverending...", "neverending..."
  end

  def test_should_allow_mailto
    assert_sanitized %{<a href="mailto:jk@jkraemer.net">my link</a>},
      %{<a href="mailto:jk&#64;jkraemer.net">my link</a>}
  end

  def test_should_not_mangle_urls_with_ampersand
    [
      %{<a href="http://www.domain.com?var1=1&amp;var2=2">my link</a>},
      %{<a href="http://www.domain.com?var1=1&var2=2">my link</a>}
    ].each do |raw|
     assert_sanitized raw, %{<a href="http://www.domain.com?var1&#61;1&amp;var2&#61;2">my link</a>}
    end
  end

  def test_should_sanitize_neverending_attribute
    assert_sanitized %{<span class="\\}, %{<span class="&#34;\\"></span>}
  end

  [
    %(<a href="javascript&#x3a;alert('XSS');">),
    %(<a href="javascript&#x003a;alert('XSS');">),
    %(<a href="javascript&#x3A;alert('XSS');">),
    %(<a href="javascript&#x003A;alert('XSS');">)
  ].each_with_index do |enc_hack, i|
    define_method "test_x03a_handling_#{i+1}" do
      assert_sanitized enc_hack, "<a></a>"
    end
  end

  def test_x03a_legitimate
    assert_sanitized %(<a href="http&#x3a;//legit">), %(<a href="http://legit"></a>)
    assert_sanitized %(<a href="http&#x3A;//legit">), %(<a href="http://legit"></a>)
  end

  def test_sanitize_ascii_8bit_string
    white_list_sanitize('<a>hello</a>'.encode('ASCII-8BIT')).tap do |sanitized|
      assert_equal '<a>hello</a>', sanitized
      assert_equal Encoding::UTF_8, sanitized.encoding
    end
  end

  def test_performance_reusing_sanitizer
    sanitizer = Rails::Html::Owasp::WhiteListSanitizer.new
    measurement = Benchmark.measure do
      10_000.times do
        sanitizer.sanitize('<a href="http://www.domain.com?var1=1&amp;var2=2">my link</a>')
      end
    end
    assert measurement.total < 2, "performance was too slow, took #{measurement.total} seconds"
  end

protected

  def full_sanitize(input, options = {})
    Rails::Html::Owasp::FullSanitizer.new.sanitize(input, options)
  end

  def link_sanitize(input, options = {})
    Rails::Html::Owasp::LinkSanitizer.new.sanitize(input, options)
  end

  def white_list_sanitize(input, options = {})
    Rails::Html::Owasp::WhiteListSanitizer.new.sanitize(input, options)
  end

  def assert_sanitized(input, expected = nil)
    if input
      assert_equal expected || input, white_list_sanitize(input)
    else
      assert_nil white_list_sanitize(input)
    end
  end

  def sanitize_css(input)
    Rails::Html::Owasp::WhiteListSanitizer.new.sanitize_css(input)
  end

  def scope_allowed_tags(tags)
    Rails::Html::Owasp::WhiteListSanitizer.allowed_tags = tags
    yield Rails::Html::Owasp::WhiteListSanitizer.new

  ensure
    Rails::Html::Owasp::WhiteListSanitizer.allowed_tags = nil
  end

  def scope_allowed_attributes(attributes)
    Rails::Html::Owasp::WhiteListSanitizer.allowed_attributes = attributes
    yield Rails::Html::Owasp::WhiteListSanitizer.new

  ensure
    Rails::Html::Owasp::WhiteListSanitizer.allowed_attributes = nil
  end
end
