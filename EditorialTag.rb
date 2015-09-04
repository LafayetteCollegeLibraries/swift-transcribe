# -*- coding: utf-8 -*-

module SwiftPoemsProject

  module EditorialMarkup

    EDITORIAL_TOKENS = ['\\']
    
    EDITORIAL_TOKEN_CLASSES = {
      'crossed·out' => 'SubstitutionTag',
      'overwritten' => 'SubstitutionTag',
    }
    
    # Base class for all editorial markup
    #
    # @todo Refactor by abstracting with the NotaBeneDelta Class
    class EditorialTag
      
      attr_reader :parent, :element, :name
      
      def initialize(token, document, parent)
        
        @document = document
        @parent = parent
        
        @name = @name || 'unclear'
        @attributes = @attributes || { }
        
        # Create the element
        @element = Nokogiri::XML::Node.new @name, @document
        
        # Add the attributes
        @attributes.each_pair do |name, value|
          
          @element[name] = value
        end
        
        # Append to the line
        @parent.add_child @element
      end
      
      def add_child(node)
         
        @element.add_child node
      end
       
      def add_text(text)
         
        node = Nokogiri::XML::Text.new text, @document
        add_child node
      end

      def parse_reason(reason)

        @element['reason'] = reason
      end
      
    end
     
    # Class for all textual insertions
    # Case 1: "\add xxx\"
    #
    class AddTag < EditorialTag
       
       def initialize(token, document, parent)
         
         @name = 'add'
         super token, document, parent
       end
     end
     
     # Class for all textual deletions
     # Case 1: "\del xxx\"
     #
     class DelTag < EditorialTag
       
       def initialize(token, document, parent)
         
         @name = 'del'
         super token, document, parent
       end
     end
     
     # Class for all textual substitutions
     # Note: *There is not ordering assumed for any of these substitutions*
     # Case 1: "\del xxx add yyy\"
     #
     class SubstitutionTag < EditorialTag

       attr_reader :del_element, :add_element
       
       def initialize(token, document, parent)
         
         @name = 'subst'
         super token, document, parent

         @del_element = Nokogiri::XML::Node.new 'del', @document
         @add_element = Nokogiri::XML::Node.new 'add', @document

         @element.add_child @del_element
         @element.add_child @add_element
       end
       
     end
     
     class UnreadableTag < EditorialTag
       
       def initialize(token, document, parent)
         
         @name = 'unclear'
         super token, document, parent
       end
       
     end
     
     class SicTag < EditorialTag
       
       def initialize(token, document, parent)
         
         @name = 'sic'
         super token, document, parent
       end
       
     end
     
     class GapTag < EditorialTag
       
       def initialize(token, document, parent)
         
         @name = 'gap'
         super token, document, parent
       end
       
     end
     
     class CroppedTag < GapTag
       
       
       def initialize(token, document, parent)
         
         @attributes = { 'agent' => 'cropping' }
         super token, document, parent
       end
       
     end
     
     class HoleTag < GapTag
       
       def initialize(token, document, parent)
         
         @attributes = { 'agent' => 'hole' }
         super token, document, parent
       end
       
     end
     
     class GutterTag < GapTag
       
       def initialize(token, document, parent)
         
         @attributes = { 'agent' => 'binding' }
         super token, document, parent
       end
     end
   end
 end
