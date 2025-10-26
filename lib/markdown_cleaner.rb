# frozen_string_literal: true

require 'kramdown'

# Utility module for cleaning markdown text
module MarkdownCleaner
  def self.clean(text)
    doc = Kramdown::Document.new text
    Kramdown::Converter::Kramdown.convert(doc.root).first
  end
end
