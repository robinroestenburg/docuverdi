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

  def table(header, body)
    "<table class=\"table table-condensed table-bordered\"><thead>#{header}</thead><tbody>#{body}</tbody></table>"
  end

  def header(text, header_level)
    if header_level == 1
      "<div class=\"page-header\"><h#{header_level}>#{text}</h#{header_level}></div>"
    else
      "<h#{header_level}>#{text}</h#{header_level}>"
    end
  end
  def image(link, title, alt_text)
    "<div class=\"image-centered\"><img src=\"#{link}\" alt=\"#{alt_text}\" /></div>"
  end
end

def markdown(text)
  options  = { autolink: true,
               space_after_headers: true,
               fenced_code_blocks: true,
               no_intra_emphasis: true,
               tables: true }
  markdown = Redcarpet::Markdown.new(HTMLwithPygments, options)
  markdown.render(text)
rescue
  'Error occurred during Markdown rendering.'
end

# Render templates using Markdown.
sections = Dir.new('sections').select { |f| f.end_with? '.md' }
output   = sections.inject("") do |output, file|
             template = File.open("sections/#{file}").read
             output + markdown(template)
           end

# Render a Haml template.
template_two = Tilt::HamlTemplate.new('index.html.haml')
output_two = template_two.render { output }

File.open('public/index.html', 'w') do |file|
  file.write output_two
end

# Render a Sass template.
style = Tilt::SassTemplate.new('style.css.sass')
style_output = style.render

File.open('public/css/style.css', 'w') do |file|
  file.write style_output
end

