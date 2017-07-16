module JWL
  class CsvExporter
    def perform(collection)
      file = File.new("exports/#{DateTime.now.strftime("%Y-%m-%d-%H-%M-%S")}.csv", 'w')

      CSV.open(file.path, 'wb') do |row|
        row << collection.first.keys
        collection.each { |collection| row << collection.values }
      end

      file.close
    end
  end
end
