require 'csv'

module Cities
  def self.lookup(city)
    result = db[city]
    return result if result
    fuzzy = db.find { |k, _| k.start_with?(city) }
    fuzzy[1] if fuzzy
  end

  def self.[](city)
    lookup(city)
  end

  def self.db
    @_db ||= begin
      csv = CSV.read(db_path)
      csv.each_with_object({}) do |e, a|
        offset = e[1].split(' ')[0].delete('(').delete(')').delete('GMT')
        a[e[0]] = offset
      end
    end
  end

  def self.db_path
    File.join(File.dirname(__FILE__), 'cities_csv', 'cities.txt')
  end
end
