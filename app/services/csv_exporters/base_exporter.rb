# frozen_string_literal: true

require 'csv'

module CsvExporters
  # Base class for CSV exporters with UTF-8 BOM support for Excel compatibility.
  #
  # @example
  #   class MyExporter < BaseExporter
  #     def headers
  #       ['Column 1', 'Column 2']
  #     end
  #
  #     def row(record)
  #       [record.field1, record.field2]
  #     end
  #   end
  #
  class BaseExporter
    # UTF-8 BOM for Excel compatibility
    BOM = "\xEF\xBB\xBF"
    COL_SEP = ';'

    def initialize(collection)
      @collection = collection
    end

    # Generates CSV content with UTF-8 BOM
    #
    # @return [String] CSV content ready for download
    def call
      BOM + CSV.generate(col_sep: COL_SEP) do |csv|
        csv << headers
        @collection.find_each { |record| csv << row(record) }
      end
    end

    private

    # Column headers for CSV
    #
    # @return [Array<String>]
    # @abstract Subclasses must implement this method
    def headers
      raise NotImplementedError, "#{self.class} must implement #headers"
    end

    # Row data for a single record
    #
    # @param record [Object] Record to convert to row
    # @return [Array]
    # @abstract Subclasses must implement this method
    def row(record)
      raise NotImplementedError, "#{self.class} must implement #row"
    end

    # Formats datetime for CSV
    #
    # @param datetime [Time, DateTime, nil]
    # @return [String, nil]
    def format_datetime(datetime)
      datetime&.strftime('%d.%m.%Y %H:%M')
    end
  end
end
