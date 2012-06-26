#!/usr/bin/env ruby

# gitlogviz
# by Benjamin Ragheb <ben@benzado.com>
# <http://github.com/benzado/gitlogviz>

# Run this script in the top level of your git working copy. The output is meant to be
# sent to GraphViz. You can either save it to a .dot file and open it with a GraphViz
# viewer app, or pipe it like this `gitlogviz | dot -Tpdf -o git-log.pdf`

# Constants

BRANCH_COLOR = 'red'
TAG_COLOR = 'blue'
REMOTE_COLOR = 'green'
SUBJECT_MAX_WIDTH = 60

# Global (gasp!) state

REFS = {}

unless File.directory? '.git'
  $stderr.puts "Not a git repository (.git directory not found)"
  exit 1
end

def nodify(name)
  name.gsub(/[^a-zA-Z0-9]/) {|c| sprintf('_%02x', c.ord) } 
end

def load_packed_refs
  return unless File.readable? '.git/packed-refs'
  File.open('.git/packed-refs') do |f|
    last_ref_name = nil
    f.each_line do |line|
      # lines like "{hash} refs/foo/bar"
      if /^([0-9a-f]+) refs\/(.+)/.match(line)
        REFS[$2] = $1
        last_ref_name = $2
      # lines like "^{hash}" which say what commit a tag points to
      elsif /^\^([0-9a-z]+)/.match(line)
        REFS[last_ref_name] = $1
      end
    end
  end
end

def load_refs
  Dir.glob('.git/refs/**/*') do |path|
    unless File.directory? path
      if /([0-9a-f]{40})/.match(File.read(path))
        name = path[10..path.length]
        REFS[name] = $1
      end
    end
  end
end

# Load packed first, so that ref-files overwrite packed ones
load_packed_refs
load_refs

branches = REFS.select {|k,v| /^heads/.match(k) }
tags = REFS.select {|k,v| /^tags/.match(k) }
remotes = REFS.select {|k,v| /^remotes/.match(k) }

puts <<-DOT
digraph git_log {
  node [shape=box];
DOT

# Put branch nodes in a subgraph so they will be grouped together at the top.
puts <<-DOT
  subgraph {
    rank=same;
DOT
branches.keys.each do |name|
  node = nodify name
  puts "    #{node} [color=#{BRANCH_COLOR}, label=\"#{name}\"];"
end
puts "  }"

# Put branch edges in the main graph (or else they will pull up the commit nodes)
puts "  // branch edges"
branches.each_pair do |name, hash|
  node = nodify name
  puts "  #{node} -> _#{hash} [color=#{BRANCH_COLOR}];"
end

# Make nodes and edges for each tag
puts "  // tag nodes and edges"
tags.each_pair do |name, hash|
  node = nodify name
  puts "  #{node} [color=#{TAG_COLOR}, label=\"#{name}\"];"
  puts "  #{node} -> _#{hash} [color=#{TAG_COLOR}];"
end

# Make nodes and edges for remote branches
puts "  // remote nodes and edges"
remotes.each_pair do |name, hash|
  node = nodify name
  puts "  #{node} [color=#{REMOTE_COLOR}, label=\"#{name}\"];"
  puts "  #{node} -> _#{hash} [color=#{REMOTE_COLOR}];"
end

# Make nodes and edges for each commit
puts "  // commit nodes and edges"
`git log --all --full-history --format="%H|%P|%an %ae|%aD (%ar)|%s"`.each_line do |line|
  hash, parent_hashes, author_name, author_date, subject = line.chomp.split("|", 5)
  if subject.length > SUBJECT_MAX_WIDTH
    subject = subject[0..SUBJECT_MAX_WIDTH] + '...'
  end
  subject.gsub!(/</, '&lt;')
  subject.gsub!(/>/, '&gt;')
  label = [
    "<FONT FACE=\"Courier\">#{hash}</FONT>",
    author_date,
    author_name,
    ' ',
    subject
  ].join("<BR/>")
  puts "  _#{hash} [label=<#{label}>];"
  parent_hashes.split(/ /).each do |parent_hash|
    puts "  _#{hash} -> _#{parent_hash};"
  end
end

puts "}"
