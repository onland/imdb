namespace :fixtures do
  desc 'Refresh spec fixtures with fresh data from IMDB.com'
  task :refresh do
    require File.expand_path(File.dirname(__FILE__) + '/../spec/spec_helper')

    ONLY = ENV['ONLY'] ? ENV['ONLY'].split(',') : []
    IMDB_SAMPLES.each_pair do |url, fixture|
      next if !ONLY.empty? && !ONLY.include?(fixture)
      dest_file = File.expand_path(File.dirname(__FILE__) + "/../spec/fixtures/#{fixture}")

      puts "Updating from #{url} -> #{dest_file}"

      data = `curl -is #{url}`
      File.open(dest_file, 'w') { |f| f.write(data) }

      sleep Random.rand(5) + 3
    end
  end
end
