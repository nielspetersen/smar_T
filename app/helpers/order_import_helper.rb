module OrderImportHelper

  def is_number? string
    true if Float(string) rescue false
  end

  def sanitize_filename(filename)
    filename.strip.tap do |name|
      # get only the filename, not the whole path
      name.sub! /\A.*(\\|\/)/, ''
      # Finally, replace all non alphanumeric, underscore
      # or periods with underscore
      name.gsub! /[^\w\.\-]/, '_'
    end
  end
end
