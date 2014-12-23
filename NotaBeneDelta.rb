# -*- coding: utf-8 -*-

module SwiftPoemsProject

  class NotaBeneDelta

    attr_reader :parent, :element, :name

    def initialize(token, document, parent)

      @document = document
      @parent = parent
    end

    def add_child(node)

      @element.add_child node
    end

    def add_text(text)

      node = Nokogiri::XML::Text.new text, @document
      add_child node
    end

    def children
      
      @element.children
    end
  end

  class UnaryNotaBeneDelta < NotaBeneDelta

    def initialize(token, document, parent)

      super

      tei_map = NB_SINGLE_TOKEN_TEI_MAP[token]

      names = tei_map.keys
      raise NotImplementedError.new "Could not create a delta using #{token}" if names.empty?

      # Always use the first name
      @name = names.first
      @element = Nokogiri::XML::Node.new @name, @document

      # Apply the attributes
      attributes = tei_map[@name]
      attributes.each_pair do |name, value|

         @element[name] = value
      end

      @parent.add_child @element
    end
  end

   class BinaryNotaBeneDelta < NotaBeneDelta

     def initialize(token, document, parent)

       super

       @element = Nokogiri::XML::Node.new token, @document
       @name = @element.name
       
       @parent.add_child @element
     end

     def close(token)

       tei_map = NB_MARKUP_TEI_MAP[@element.name][token]

       names = tei_map.keys
       raise NotImplementedError.new "Could not close the delta #{@element.name} using #{token}" if names.empty?

       # Always use the first name
       @name = names.first

       # Apply the attributes
       attributes = tei_map[@name]
       attributes.each_pair do |name, value|

         @element[name] = value
       end

       @element.name = @name
     end
   end
end
