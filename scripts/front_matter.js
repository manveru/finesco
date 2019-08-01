#!/usr/bin/env node

const md = require('markdown-it')({
  html: true,
  linkify: true,
  typographer: true,
})

const fs = require('fs')
const matter = require('gray-matter')

const input = fs.readFileSync(process.argv[2])
const parts = matter(input, {excerpt_separator: '<!--more-->'})

const output = {
  body: md.render(parts.content),
  teaser: parts.excerpt,
  ...parts.data
}

console.log(JSON.stringify(output))
