# -*- coding: utf-8 -*-

module SwiftPoemsProject

  class TeiHead
    
    attr_reader :elem, :footnote_index
    attr_accessor :has_opened_tag, :current_leaf

    def note_number(number)

      @elem['n'] = number

      @xml_id = "spp-#{@heads.id}-headnote-#{number}"
      @elem['xml:id'] = @xml_id
    end

    def line_group_number(number, element = @current_leaf)

      element['n'] = number
      @current_line_group_xml_id = "#{@xml_id}-line-group-#{number}"
      
      element['xml:id'] = @current_line_group_xml_id
    end

    def line_number(number, element = @current_leaf)

      element['n'] = number
      @current_element_xml_id = "#{@current_line_group_xml_id}-line-#{number}"

      element['xml:id'] = @current_element_xml_id
    end

    def add_element(element)

      # Retrieve the last <head>
      xpath = "//TEI:head[@type='note']"
      head_elements = @heads.elem.xpath(xpath, 'TEI' => 'http://www.tei-c.org/ns/1.0')

      if head_elements.empty?

        # Ensure that this is the first element
        if @heads.elem.children.empty?
          @heads.elem.add_child element
        else
          @heads.elem.children.first.add_previous_sibling element
        end
      else
        head_elements.last.add_next_sibling element
      end
    end
    
    def initialize(document, heads, index, options = {})
      
      @document = document
      # @poem = heads.parser.poem
      @heads = heads
      
      @elem = Nokogiri::XML::Node.new('head', @document)
      @elem['type'] = 'note'

      note_number index

#      @heads.elem.add_child @elem
      add_element(@elem)

      # Insert handling for paragraphs within headnotes
      @current_leaf = @elem.add_child Nokogiri::XML::Node.new 'lg', @document
      @paragraph_index = 1
      line_group_number @paragraph_index

      # Resolves SPP-244
      # @todo Refactor
      @current_leaf['type'] = 'headnote'

      # Resolves SPP-243
      # @todo Refactor
      @current_leaf = @current_leaf.add_child Nokogiri::XML::Node.new 'l', @document
      line_number 1

      @tokens = []

      @footnote_opened = false
      @flush_left_opened = false
      @flush_right_opened = false

      # SPP-156
      @footnote_index = options[:footnote_index] || 0
    end
    
    def pushToken(token)

      # Hard-coding support for footnote parsing
      # @todo Refactor
      if NB_MARKUP_TEI_MAP.has_key? @current_leaf.name and not /«FN./.match(token)

        if NB_TERNARY_TOKEN_TEI_MAP.has_key? @current_leaf.name and NB_TERNARY_TOKEN_TEI_MAP[@current_leaf.name][:secondary].has_key? token
          # One cannot resolve the tag name and attributes until both tags have been fully parsed
          
          # Set the name of the current token from the map
          @current_leaf.name = NB_TERNARY_TOKEN_TEI_MAP[@current_leaf.name][:secondary][token].keys[0]
          @current_leaf = @current_leaf.parent

          newLeaf = Nokogiri::XML::Node.new token, @document
          @current_leaf.add_child newLeaf
          @current_leaf = newLeaf

        elsif NB_MARKUP_TEI_MAP[@current_leaf.name].has_key? token # If this token closes the currently opened token

          if /^«FN/.match @current_leaf.name and /»/.match token

            @footnote_index += 1
            @current_leaf['n'] = @footnote_index

            # Extend for SPP-253
            xml_id = "spp-#{@heads.id}-footnote-headnote-#{@footnote_index}"
            @current_leaf['xml:id'] = xml_id

            target = "##{xml_id}"
            source = "##{@current_leaf_xml_id}"

            # Add an inline <ref> element
            ref = Nokogiri::XML::Node.new 'ref', @document
            ref.content = @footnote_index
            ref['target'] = target
            @current_leaf.add_previous_sibling ref
         
            # Add an element to <linkGrp>
            @heads.transcript.tei.link_group.add_link source, target
          end

          # Iterate through all of the markup and set the appropriate TEI attributes
          attribMap = NB_MARKUP_TEI_MAP[@current_leaf.name][token].values[0]
          @current_leaf[attribMap.keys[0]] = attribMap[attribMap.keys[0]]

          # One cannot resolve the tag name and attributes until both tags have been fully parsed
          @current_leaf.name = NB_MARKUP_TEI_MAP[@current_leaf.name][token].keys[0]
          @current_leaf = @current_leaf.parent
         
          @has_opened_tag = false

          # @todo Refactor
          @heads.opened_tags.shift
          
          opened_tag = @heads.opened_tags.first

          while not opened_tag.nil? and NB_MARKUP_TEI_MAP.has_key? opened_tag.name and NB_MARKUP_TEI_MAP[opened_tag.name].has_key? token

            closed_tag = @heads.opened_tags.shift

            closed_tag_name = NB_MARKUP_TEI_MAP[closed_tag.name][token].keys[0]

            # @todo Integrate Nota Bene Delta Objects
            NB_MARKUP_TEI_MAP[closed_tag.name][token][closed_tag_name].each_pair do |attrib_name, attrib_value|

              closed_tag[attrib_name] = attrib_value
            end
            closed_tag.name = closed_tag_name

            opened_tag = @heads.opened_tags.first
          end

          # Work-around for "overridden" Nota Bene Deltas
          if not( /^«FN/.match @current_leaf.name and /»/.match token) and token != '«MDNM»' and not /\.»/.match token
            
            # Add the cloned token
            newLeaf = Nokogiri::XML::Node.new token, @document
            @current_leaf.add_child newLeaf
            @current_leaf = newLeaf
            @has_opened_tag = true

            @heads.opened_tags.unshift @current_leaf
          end

        elsif NB_MARKUP_TEI_MAP.has_key? token
          
          # Add a new child node to the current leaf
          # Temporarily use the token itself as a tagname
          newLeaf = Nokogiri::XML::Node.new token, @document
          @current_leaf.add_child newLeaf
          @current_leaf = newLeaf
          @has_opened_tag = true

          @heads.opened_tags.unshift @current_leaf
        elsif NB_SINGLE_TOKEN_TEI_MAP.has_key? token

          newLeaf = Nokogiri::XML::Node.new token, @document

          newLeaf.name = NB_SINGLE_TOKEN_TEI_MAP[token].keys[0]

          NB_SINGLE_TOKEN_TEI_MAP[token][newLeaf.name].each do |name, value|

            newLeaf[name] = value
          end

          @current_leaf.add_child newLeaf

          # @flush_left_opened = /«FC»/.match(token)
          # @flush_right_opened = /«LD ?»/.match(token)
          @flush_left_opened = false
          @flush_right_opened = false
        else
          
          raise NotImplementedError.new "Unhandled token: #{token}"
        end

      elsif @flush_right_opened or @flush_left_opened or @footnote_opened # @todo Refactor
        
        # Add a new child node to the current leaf
        # Temporarily use the token itself as a tagname
        newLeaf = Nokogiri::XML::Node.new token, @document

        @current_leaf.name = NB_SINGLE_TOKEN_TEI_MAP[token].keys[0]

        @current_leaf.add_child newLeaf
        @current_leaf = newLeaf
        # @has_opened_tag = true

      elsif NB_SINGLE_TOKEN_TEI_MAP.has_key? token

        newLeaf = Nokogiri::XML::Node.new token, @document

        newLeaf.name = NB_SINGLE_TOKEN_TEI_MAP[token].keys[0]

        NB_SINGLE_TOKEN_TEI_MAP[token][newLeaf.name].each do |name, value|

          newLeaf[name] = value
        end

        @current_leaf.add_child newLeaf
        @current_leaf = newLeaf

        # @flush_left_opened = /«FC»/.match(token)
        # @flush_right_opened = /«LD ?»/.match(token)
        @flush_left_opened = false
        @flush_right_opened = false

      else

        # Add a new child node to the current leaf
        # Temporarily use the token itself as a tagname
        newLeaf = Nokogiri::XML::Node.new token, @document
        @current_leaf.add_child newLeaf
        @current_leaf = newLeaf
        @has_opened_tag = true

        @heads.opened_tags.unshift @current_leaf
      end

      @tokens << token
    end
    
    # Add this as a text node for the current line element
    def pushText(token)

      # @todo Remove and refactor
      token = token.gsub(/«.{4}?»/, '')

      raise NotImplementedError.new "Failure to parse the following token within a headnote: #{token}" if /«.{2}/.match token

      # Remove the 8 character identifier from the beginning of the line
      indexMatch = /\s{3}(\d+)\s{2}/.match token
      if indexMatch
        
        # @elem['n'] = indexMatch.to_s.strip
        note_number indexMatch.to_s.strip
        token = token.sub /\s{3}(\d+)\s{2}/, ''
      end
      
      # Replace all Nota Bene deltas with UTF-8 compliant Nota Bene deltas
      NB_CHAR_TOKEN_MAP.each do |nbCharTokenPattern, utf8Char|
        
        token = token.gsub(nbCharTokenPattern, utf8Char)
      end
      
      if token == '|'
        
        @current_leaf.add_child Nokogiri::XML::Node.new 'lb', @document
      else
        
        @current_leaf.add_child Nokogiri::XML::Text.new token, @document
      end
    end

    def pushParagraph

      @current_leaf = @current_leaf.parent.parent
      new_paragraph = Nokogiri::XML::Node.new 'lg', @document
      @paragraph_index += 1
      # new_paragraph['n'] = @paragraph_index
      line_group_number @paragraph_index, new_paragraph

      @current_leaf.add_child new_paragraph

      @current_leaf = new_paragraph

      # Resolves SPP-244
      # @todo Refactor
      @current_leaf['type'] = 'headnote'

      # Resolves SPP-243
      # @todo Refactor
      @current_leaf = @current_leaf.add_child Nokogiri::XML::Node.new 'l', @document
      # @current_leaf['n'] = 1
      line_number 1

      if not @heads.opened_tags.empty?

        prev_opened_tag = @heads.opened_tags.first
        current_opened_tag = Nokogiri::XML::Node.new prev_opened_tag.name, @document

        @current_leaf.add_child current_opened_tag
        @current_leaf = current_opened_tag
      end
    end
    
    def push(token)

      # This handles anomalous cases in which the editor did not properly encode a Nota Bene modecode sequence
      # e. g. [...]«MDUL» of wearing Scarlet and Gold, with what they call «FN1·«MDNM»Wigs with long black Tails, worn for some Years past. «MDUL»November«MDNM» 1738.»[...]
      # ...where «MDNM» should close before «FN1· is opened
      # Resolves SPP-559
      if token == '«MDNM»' and /«FN./.match(@current_leaf.name) and @heads.opened_tags.length >= 2

        # @todo Refactor
        closed_tag_name = NB_MARKUP_TEI_MAP[@heads.opened_tags[1].name][token].keys[0]

        # @todo Integrate Nota Bene Delta Objects
        NB_MARKUP_TEI_MAP[@heads.opened_tags[1].name][token][closed_tag_name].each_pair do |attrib_name, attrib_value|

          @heads.opened_tags[1][attrib_name] = attrib_value
        end
        @heads.opened_tags[1].name = closed_tag_name

        @heads.opened_tags[0].remove
        @heads.opened_tags[1].parent.add_child @heads.opened_tags[0]
        @heads.opened_tags.delete_at(1)

      elsif token == '_' # Open a new paragraph for the '_' operator
        pushParagraph
      elsif NB_SINGLE_TOKEN_TEI_MAP.has_key? token or
          (NB_TERNARY_TOKEN_TEI_MAP.has_key? @current_leaf.name and NB_TERNARY_TOKEN_TEI_MAP[@current_leaf.name][:secondary].has_key? token) or
          (NB_MARKUP_TEI_MAP.has_key? @current_leaf.name and NB_MARKUP_TEI_MAP[@current_leaf.name].has_key? token) or
          NB_MARKUP_TEI_MAP.has_key? token
        
        pushToken token
      else
        
        pushText token
      end
    end
  end
end
