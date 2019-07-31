#!/usr/bin/env ruby

require 'yaml'
require 'json'
require 'strscan'
require 'date'
require 'redcarpet'

s = StringScanner.new(File.read(ARGV[0]))
s.scan_until(/---\n/)
front = s.scan_until(/---\n/)
front_match = s.matched
teaser = s.scan_until(/<!--\s*more\s*-->/)
teaser_match = s.matched
s.unscan if teaser
markdown_source = s.rest

markdown = Redcarpet::Markdown.new(
  Redcarpet::Render::HTML.new,
  tables: true,
  autolink: true,
  space_after_headers: true
)

meta = { 'teaser' => '' }

if front
  yaml = "---\n" + front[0..-(front_match.size + 1)]
  meta = YAML.safe_load(yaml, [Date]) if front
end

if teaser
  md = teaser[0..-(teaser_match.size + 1)].strip
  meta['teaser'] = markdown.render(md)
end

meta['body'] = markdown.render(markdown_source)

puts JSON.pretty_unparse(meta)
