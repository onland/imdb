namespace :fixtures do
  desc 'Refresh spec fixtures with fresh data from IMDB.com'
  task :refresh do

    # ENV variable to tell spec_helper not to try to read any fixture.
    # It would fail with Errno::ENOENT for new fixtures otherwise
    ENV['FIXTURES_UPDATE'] = 'true'
    require File.expand_path(File.dirname(__FILE__) + '/../spec/spec_helper')

    ONLY = ENV['ONLY'] ? ENV['ONLY'].split(',') : []

    # Forces curl to download pages in English with '-H "Accept-Language:en-US;en"'
    curl_headers = Imdb::HTTP_HEADER.map{|k, v| "-H \"#{k}:#{v}\""}.join(' ')

    IMDB_SAMPLES.each_pair do |url, fixture|
      next if !ONLY.empty? && !ONLY.include?(fixture)
      dest_file = File.expand_path(File.dirname(__FILE__) + "/../spec/fixtures/#{fixture}")

      puts "Updating from #{url} -> #{dest_file}"

      # Downloads url in English and remove Proxy information from response.
      data = `curl -is #{curl_headers} \"#{url}\" | grep -v '^Via:'`
      File.open(dest_file, 'w') { |f| f.write(data) }

      sleep Random.rand(5) + 3
    end
  end
end
