require 'redcarpet'
require 'pygments.rb'
require 'nokogiri'
require 'tilt'
require 'haml'

class HTMLwithPygments < Redcarpet::Render::HTML
  def block_code(code, language)
    language, show_line_numbers = language.split(',')
    if show_line_numbers
      Pygments.highlight(code, :lexer => language, :options => { :linenos => 'inline' })
    else
      Pygments.highlight(code, :lexer => language)
    end
  end

# def image(link, title, alt_text)
#   "<div class=\"thumbnail-wrapper\"><div class=\"thumbnail\"><img src=\"#{link}\" /></div></div>"
# end
end

def markdown(text)
  options  = { :autolink => true, :space_after_headers => true, :fenced_code_blocks => true }
  markdown = Redcarpet::Markdown.new(HTMLwithPygments, options)
  markdown.render(text)
rescue
  'Error occurred during Markdown rendering.'
end


# Render a template using Markdown.

output = ""

Dir.new('.').select { |f| f.end_with? '.md' }.each { |file|
  template = File.open(file).read
  output += markdown(template)
}

# Render a Haml template.
template_two = Tilt::HamlTemplate.new('index.html.haml')
output_two = template_two.render { output }

File.open('public/index.html', 'w') do |file|
  file.write output_two
end

# Render a Haml template.
style = Tilt::SassTemplate.new('style.css.sass')
style_output = style.render

File.open('public/css/style.css', 'w') do |file|
  file.write style_output
end


# Load up output in Nokogiri and perform manipulation.
#@manual = Nokogiri::HTML(output).css('body')
#
#@manual.css('code').each do |code|
#  # Highlight code
#  highlighted = Pygments.highlight(code.text, :lexer => 'ruby')
#
#  code.replace highlighted
#end
#
#puts @manual


