module Imdb
  module Util
    private

    # Get node content from document at xpath.
    # Returns stripped content if present, nil otherwise.
    # Apply block (if defined) to node.
    def get_node(xpath, doc = document)
      node = doc.at(xpath)
      if node
        if block_given?
          yield node
        else
          node.content.strip
        end
      end
    end

    # Get nodes content from document at xpath.
    # Returns stripped content for each node, or apply block to each node if present.
    def get_nodes(xpath, doc = document, &block)
      nodes = doc.search(xpath)
      if block_given?
        nodes.map(&block)
      else
        nodes.map { |node| node.content.strip }
      end
    end
  end
end
