# frozen_string_literal: true

require 'yaml'
require 'time'
require 'date'
require 'fileutils'

FileUtils.rm_rf 'tmp'
FileUtils.mkdir_p 'tmp'

Dir.glob('info/*.md') do |md|
  _, header, body = File.read(md).split('---', 3)
  frontmatter = YAML.safe_load(header, [Time, Date])

  date = frontmatter['date']
  case date
  when String
    date = Time.strptime(date, '%Y-%m-%d').to_date
  when Time
    date = date.to_date
  when nil
    raise "#{md} has no date"
  end

  File.open("tmp/#{date.strftime('%Y-%m-%d')}.md", 'w+') do |io|
    io << {
      'date' => date,
      'title' => frontmatter.fetch('title').strip
    }.to_yaml
    io << "---\n"
    io << body
  end
end
