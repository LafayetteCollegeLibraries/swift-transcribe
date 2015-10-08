# -*- coding: utf-8 -*-

module SwiftPoemsProject

  module EditorialMarkup

    EDITORIAL_TOKENS = ['\\']

    EDITORIAL_TOKEN_PATTERNS = [
                                /(written above deleted)\s(.+)/,
#                                /(alt above)\s(.+)/,
#                                /(overwriting something erased and)\s(.+)/,
                               ]
    
    EDITORIAL_TOKEN_CLASSES = {
      'crossed·out' => 'SubstitutionTag',
      'overwritten' => 'SubstitutionTag',
      'deleted, inserting' => 'SubstitutionTag',
      'character·obliterated' => 'EmptyDelTag',
      'word·scrawled·over' => 'EmptyDelTag',
      'caret·add' => 'AddTag',
      'add·caret' => 'AddTag',
      'del' => 'DelTag',
      'add' => 'AddTag',
      'inserted' => 'AddTag',
      'inserted (as alternative?)' => 'AltReadingTag',
      'apparently overwriting' => 'OverwritingTag',
      'overwriting' => 'OverwritingTag',
      'written above deleted' => 'OverwritingTag',
      'alt above' => 'AltReadingTag',
      'overwriting something else' => 'UnclearOverwritingTag',
      'a later correction overwriting ?' => 'UnclearOverwritingTag',
      'over something else erased' => 'UnclearOverwritingTag',
      'overwriting something erased and' => 'InsertionOverwritingTag',
    }

    EDITORIAL_TOKEN_REASONS = [
                               'large ink-blot',
                               'overwriting'
                              ]
    
    # Base class for all editorial markup
    #
    # @todo Refactor by abstracting with the NotaBeneDelta Class
    class EditorialTag
      
      attr_reader :tag, :parent, :element, :name
      
      def initialize(token, document, parent)
        
        @tag = token
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

        reason = reason.gsub /·/, ' '
        @element['reason'] = reason unless reason.empty?
      end      
    end

    # Class for all textual insertions
    # Case 1: "\add xxx\"
    #
    class AddTag < EditorialTag
       
       def initialize(token, document, parent)
         
         @name = 'add'
         super token, document, parent
         @element.content = token
       end
     end
     
     # Class for all textual deletions
     # Case 1: "\del xxx\"
     #
     class DelTag < EditorialTag
       
       def initialize(token, document, parent)
         
         @name = 'del'
         super token, document, parent
         @element.content = token
       end

       def parse_reason(token)

         # No-Op
         nil
       end
     end

     class EmptyDelTag < DelTag
       
       def initialize(token, document, parent)

         super token, document, parent

         # Create the element
         gap = Nokogiri::XML::Node.new 'gap', @document
         token = token.gsub /·/, ' '
         gap['reason'] = token
         
         # Append to the <del>
         @element.add_child gap
       end

       def parse_reason(token)

         # No-Op
         nil
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

     # Case: \has·«MDUL»overwriting«MDNM»·had\
     class OverwritingTag < EditorialTag

       attr_reader :del_element, :add_element

       def initialize(token, document, parent)
         
         @name = 'subst'
         super token, document, parent

         @add_element = Nokogiri::XML::Node.new 'add', @document
         @del_element = Nokogiri::XML::Node.new 'del', @document

         @element.add_child @add_element
         @element.add_child @del_element
       end
     end

     class UnclearOverwritingTag < OverwritingTag

       attr_reader :add_elements

       def initialize(token, document, parent)

         super token, document, parent

         unclear_element = Nokogiri::XML::Node.new 'unclear', @document
         @del_element.add_child unclear_element
       end
     end

     # @todo Refactor with UnclearOverwritingTag
     class InsertionOverwritingTag < OverwritingTag

       def initialize(token, document, parent)

         super token, document, parent

         @element['reason'] = token
       end
     end
     
     class UnreadableTag < EditorialTag
       
       def initialize(token, document, parent)
         
         @name = 'unclear'
         super token, document, parent
       end
     end

     class AltReadingTag < EditorialTag
       attr_reader :rdg_u_element, :rdg_v_element

       def initialize(token, document, parent)
         
         @name = 'app'
         super token, document, parent

         # @todo Implement support for @wit values
         @rdg_u_element = Nokogiri::XML::Node.new 'rdg', @document
         @rdg_v_element = Nokogiri::XML::Node.new 'rdg', @document

         @element.add_child @rdg_u_element
         @element.add_child @rdg_v_element
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
