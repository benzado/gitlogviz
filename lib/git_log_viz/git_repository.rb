module GitLogViz
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
end
