require 'kramdown'

module MarkdownCleaner
  def self.clean(text)
    doc = Kramdown::Document.new text
    Kramdown::Converter::Kramdown.convert(doc.root).first
  end
end
