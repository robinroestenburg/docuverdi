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

doc_directory = ARGV.shift
doc_title     = ARGV.shift
show_toc      = ARGV.shift

# Render templates using Markdown.
sections = Dir.new("#{doc_directory}/sections").select { |f| f.end_with? '.md' }
output   = sections.inject("") do |output, file|
             template = File.open("#{doc_directory}/sections/#{file}").read
             output + markdown(template)
           end

# Parse rendered template using Nokogiri
template = Nokogiri::HTML(output).css('body')

if show_toc

  # Link <h1> <h2> and <h3> tags and create a table of contents.
  links = template.css('h1, h2').collect do |node|
    href = node.text.downcase.gsub(/\s/, '_')
    name = node.text
    level = node.name[1].to_i
    node.inner_html = '<a name="' + href + '" href="#' + href + '">' + node.inner_html + '</a>'

    { :name => name, :href => href, :level => level }
  end
  links.compact!
  links = links[2..-1]
  links.reverse.each do |link|
    template.css('.page-header').first.add_next_sibling("<div class='link'><h#{link[:level]+3}><a href='##{link[:href]}'>#{link[:name]}</a></h#{link[:level]+3}></div>")
  end
end

# Render a Haml template.
template_two = Tilt::HamlTemplate.new('index.html.haml')
output_two = template_two.render(Object.new,
                                 output: template.to_s,
                                 title: doc_title)

File.open("#{doc_directory}/public/index.html", 'w') do |file|
  file.write output_two
end

# Render a Sass template.
style = Tilt::SassTemplate.new('style.css.sass')
style_output = style.render

File.open("#{doc_directory}/public/css/style.css", 'w') do |file|
  file.write style_output
end

