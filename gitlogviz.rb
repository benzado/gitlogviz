#!/usr/bin/env ruby

# gitlogviz
# by Benjamin Ragheb <ben@benzado.com>
# <http://github.com/benzado/gitlogviz>

# Run this script in the top level of your git working copy. The output is meant
# to be sent to GraphViz. You can either save it to a .dot file and open it with
# a GraphViz viewer app, or create a PDF by piping output to dot like so:
#
#   gitlogviz | dot -Tpdf -o git-log.pdf`
#

# Constants

BRANCH_COLOR = :red
STASH_COLOR = :orange
TAG_COLOR = :blue
REMOTE_COLOR = :green
SUBJECT_MAX_WIDTH = 60

# Global (gasp!) state

class GitRepository

  def initialize
    @refs = Hash.new
    # Annotated tags will appear as refs/tags/whatever and refs/tags/whatever^{},
    # we read both and overwrite the first with the second.
    `git show-ref -d`.each_line do |line|
        if %r<^([0-9a-f]{40}) refs/(.+?)(\^\{\})?$>.match(line.chomp)
            @refs[$2] = $1
        end
    end
  end

  def select_refs(pattern)
    @refs.select { |name,hash| pattern.match(name) }
  end

  def branches
    @branches ||= select_refs(/^heads/)
  end
  def tags
    @tags ||= select_refs(/^tags/)
  end
  def remotes
    @remotes ||= select_refs(/^remotes/)
  end
  def stashes
    @stashes ||= select_refs(/^stash/)
  end

  Commit = Struct.new(:hash, :parent_hashes, :author_name, :author_date, :subject)

  def each_commit
    `git log --all --full-history --format="%H|%P|%an %ae|%aD (%ar)|%s"`.each_line do |line|
      # hash, parent_hashes, author_name, author_date, subject
      args = line.chomp.split("|", 5)
      yield Commit.new(*args)
    end
  end

end

class DotFile

  def initialize(output)
    @f = output
    @indent = 0
  end

  def nodify(name)
    '_' + name.gsub(/[^a-zA-Z0-9]/) {|c| sprintf('_%02x', c.ord) }
  end

  def puts(line)
    @f.puts ('  ' * @indent) + line
  end

  def indent
    @indent += 1
    yield
    @indent -= 1
  end

  def digraph
    puts "digraph git_log {"
    indent do
      puts "node [shape=box];"
      yield
    end
    puts "}"
  end

  def subgraph
    puts "subgraph {"
    indent do
      puts "rank=same;"
      yield
    end
    puts "}"
  end

  def comment(text)
    puts "// #{text}"
  end

  def attr_list(attrs)
    if attrs
      list = attrs.map do |k,v|
        v.kind_of?(String) ? "#{k}=\"#{v}\"" : "#{k}=#{v}"
      end
      ' [' + list.join(', ') + ']'
    else
      ''
    end
  end

  def node(name, attrs)
    puts "#{nodify(name)}#{attr_list(attrs)};"
  end

  def edge(from, to, attrs = nil)
    puts "#{nodify(from)} -> #{nodify(to)}#{attr_list(attrs)};"
  end

  class HTML
    def initialize
      @source = String.new
    end
    def element(name, attrs = {})
      @source << "<#{name}"
      attrs.each do |key, value|
        @source << " #{key}=\"#{value}\""
      end
      if block_given?
        @source << ">"
        yield
        @source << "</#{name}>"
      else
        @source << "/>"
      end
    end
    def text(text)
      @source << text.gsub(/</, '&lt;').gsub(/>/, '&gt;').gsub(/&/, '&amp;')
    end
    alias_method :<<, :text
    def to_s
      "<#{@source}>"
    end
  end

end

unless File.directory? '.git'
  $stderr.puts "Not a git repository (.git directory not found)"
  exit 1
end

git = GitRepository.new
dot = DotFile.new($stdout)

dot.digraph do
  # Put branch nodes in a subgraph so they will be grouped together at the top.
  dot.subgraph do
    git.branches.keys.each do |name|
      dot.node name, color: BRANCH_COLOR, label: name
    end
    git.stashes.keys.each do |name|
      dot.node name, color: STASH_COLOR, label: name
    end
  end
  # Put branch edges in the main graph (or else they will pull up the commit nodes)
  dot.comment "branch edges"
  git.branches.each_pair do |name, hash|
    dot.edge name, hash, color: BRANCH_COLOR
  end
  dot.comment "stash edges"
  git.stashes.each_pair do |name, hash|
    dot.edge name, hash, color: STASH_COLOR
  end
  # Make nodes and edges for each tag
  dot.comment "tag nodes and edges"
  git.tags.each_pair do |name, hash|
    dot.node name, color: TAG_COLOR, label: name
    dot.edge name, hash, color: TAG_COLOR
  end
  # Make nodes and edges for remote branches
  dot.comment "remote nodes and edges"
  git.remotes.each_pair do |name, hash|
    dot.node name, color: REMOTE_COLOR, label: name
    dot.edge name, hash, color: REMOTE_COLOR
  end
  # Make nodes and edges for each commit
  dot.comment "commit nodes and edges"
  git.each_commit do |commit|

    subject = commit.subject.dup
    if subject.length > SUBJECT_MAX_WIDTH
      subject = subject[0..SUBJECT_MAX_WIDTH] + '...'
    end

    label = DotFile::HTML.new
    label.element :FONT, 'FACE' => 'Courier' do
      label << commit.hash
    end
    label.element :BR; label << commit.author_date
    label.element :BR; label << commit.author_name
    label.element :BR; label << ' '
    label.element :BR; label << subject

    dot.node commit.hash, label: label
    commit.parent_hashes.split(/ /).each do |parent_hash|
      dot.edge commit.hash, parent_hash
    end

  end
end
