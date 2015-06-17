module GitLogViz
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
end
