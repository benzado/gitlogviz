module GitLogViz
  class Command
    BRANCH_COLOR = :red
    STASH_COLOR = :orange
    TAG_COLOR = :blue
    REMOTE_COLOR = :green
    SUBJECT_MAX_WIDTH = 60

    def run
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
    end
  end
end
