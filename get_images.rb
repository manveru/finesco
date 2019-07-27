# frozen_string_literal: true

require 'open-uri'
require 'fileutils'

FileUtils.mkdir_p('images/uploads')

Dir.glob('info/*.md') do |md|
  content = File.read(md)

  urls = content.scan(/[^(]+finesco\S+\.(?:jpg|png)[^)]*/)

  urls.each do |url|
    filename = File.basename(url)
    filename = filename[/^[^?]+/]
    dest = "images/uploads/#{filename}"

    unless File.exist?(dest)
      puts "#{url} => #{dest}"

      URI(url).open do |from_io|
        File.open(dest, 'w+') do |to_io|
          IO.copy_stream(from_io, to_io)
        end
      end
    end

    content.gsub!(url, "/images/uploads/#{filename}")
    File.write(md, content)
  end
end
