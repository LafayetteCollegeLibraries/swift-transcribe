# -*- coding: utf-8 -*-

module SwiftPoemsProject

   class TeiLine

     attr_reader :elem, :has_opened_tag, :opened_tag, :opened_tags

     def initialize(workType, stanza, options = {})

       @workType = workType
       @stanza = stanza

       # Refactor
       @has_opened_tag = options[:has_opened_tag] || false
       @opened_tags = options[:opened_tags] || []

       # @opened_tag ||= options[:opened_tag]

       # @teiDocument = teiDocument
       @teiDocument = stanza.document

       @lineElemName = @workType == POEM ? 'l' : 'p'

       # Set the current leaf of the tree being constructed to be the root node itself
       @elem = Nokogiri::XML::Node.new(@lineElemName, @teiDocument)
       stanza.elem.add_child @elem

       # If there is an open tag...
       # if @has_opened_tag

       # If there are opened tags...

       elem = @elem

       # debugOutput = @opened_tags.map { |tag| tag.to_xml }
       # puts "Line added with the following opened tags: #{debugOutput}\n\n"

       if not @opened_tags.empty?

         # Work-around
         last_tag_name = @lineElemName

         @opened_tags.each do |opened_tag|

           # puts "Appending opened tag: #{opened_tag}"

           # @todo Refactor
           if last_tag_name == opened_tag.name

             # puts "TRACE: #{opened_tag.children}"
             elem.add_child opened_tag.children
           else

             # ...append the child tag and add an element
=begin
             opened_tag = Nokogiri::XML::Node.new(opened_tag.name, @teiDocument)
             elem = elem.add_child opened_tag
=end
             elem = elem.add_child opened_tag.element

             # Update the stanza
             # This duplicates tokens between lines, but does ensure that tags are passed between stanzas
             @stanza.opened_tags.unshift opened_tag

             # Append the opened tag 
             # @stanza.opened_tags.unshift opened_tag

             # @stanza.opened_tags.unshift elem.add_child(opened_tag)
             @current_leaf = opened_tag
           end

           last_tag_name = opened_tag.name
         end
       else

         @current_leaf = @elem
       end

       @tokens = []
     end

     # Add this as a text node for the current line element
     def pushText(token)

       # Remove the 8 character identifier from the beginning of the line
       indexMatch = /\s{3}(\d+)\s{2}/.match token
       indexMatch = /([0-9A-Z\!\-]{8})   /.match(token) if not indexMatch
       indexMatch = /([0-9A-Z]{8})   /.match(token) if not indexMatch

       # puts token

       if indexMatch

         @elem['n'] = indexMatch.to_s.strip

         # token = token.sub /[!#\$A-Z0-9]{8}\s{3}(\d+)\s{2}_?/, ''
         token = token.sub /\s{3}(\d+)\s{2}_?/, ''
       end

       # Transform triplet indicators for the stanza
       if /\s3\}$/.match token

         @stanza.elem['type'] = 'triplet'
         token = token.sub /\s3\}$/, ''
       end

=begin
new stanza token: «MDUL»
new stanza token: Upon the Water cast thy Bread,
line text: Upon the Water cast thy Bread,
new stanza token: 250-0201   142  |And after many Days thou'lt find it
new line token:    142  |And after many Days thou'lt find it
line text:    142  |And after many Days thou'lt find it
new stanza token: «MDNM»
new line token: «MDNM»
line text: «MDNM»
=end

       # Transform pipes into @rend values
       if /\|/.match token and @current_leaf === @elem

         indentValue = (token.split /\|/).size - 1

         @current_leaf['rend'] = 'indent(' + indentValue.to_s + ')'
         token = token.sub /\|/, ''
       end

       # Replace all Nota Bene deltas with UTF-8 compliant Nota Bene deltas
       NB_CHAR_TOKEN_MAP.each do |nbCharTokenPattern, utf8Char|
                   
         token = token.gsub(nbCharTokenPattern, utf8Char)
       end

       # Implement handling for complex textual content
       # e. g. underdot vs. non-underdot and @rend attribute values
       #

=begin
       if @current_leaf.is_a? SwiftPoemsProject::NotaBeneDelta

         @current_leaf.add_text token
       else

         @current_leaf.add_child Nokogiri::XML::Text.new token, @teiDocument
       end
=end
       @current_leaf.add_child Nokogiri::XML::Text.new token, @teiDocument
     end

     def pushSingleToken(token)

=begin
       singleTag = @current_leaf.add_child Nokogiri::XML::Node.new NB_SINGLE_TOKEN_TEI_MAP[token].keys[0], @teiDocument
=end
       if NB_DELTA_FLUSH_TEI_MAP.has_key? token

         current_leaf = FlushDelta.new(token, @teiDocument, @current_leaf)

       elsif NB_DELTA_ATTRIB_TEI_MAP.has_key? token

         current_leaf = AttributeNotaBeneDelta.new(token, @teiDocument, @current_leaf)
       else

         single_tag = UnaryNotaBeneDelta.new(token, @teiDocument, @current_leaf)
       end
     end

     def pushTermTernaryToken(token, opened_tag)

       # The initial tag for the ternary sequence
       opened_init_tag = @stanza.opened_tags[1]

       while not @stanza.opened_tags.empty? and NB_TERNARY_TOKEN_TEI_MAP.has_key? opened_init_tag.name and NB_TERNARY_TOKEN_TEI_MAP[opened_init_tag][:secondary].has_key? opened_tag.name and NB_TERNARY_TOKEN_TEI_MAP[opened_init_tag][:terminal].has_key? token

         raise NotImplementedError, "Terminal ternary token for #{token}"

         # This reduces the total number of opened tags within the stanza
         closed_tag = @stanza.opened_tags.shift

         # Also, reduce the number of opened tags for this line
         # @todo refactor
         @opened_tags.shift

         # logger.debug "Closing tag: #{closed_tag.name}..."

         # Iterate through all of the markup and set the appropriate TEI attributes
         attribMap = NB_MARKUP_TEI_MAP[closed_tag.name][token].values[0]
         closed_tag[attribMap.keys[0]] = attribMap[attribMap.keys[0]]

         # One cannot resolve the tag name and attributes until both tags have been fully parsed
         closed_tag.name = NB_MARKUP_TEI_MAP[closed_tag.name][token].keys[0]
         
         # Continue iterating throught the opened tags for the stanza
         opened_tag = @stanza.opened_tags.first
       end

       # Once all of the stanza elements have been closed, retrieve the last closed tag for the line
       @current_leaf = closed_tag.parent

       @has_opened_tag = !@opened_tags.empty?
     end

     def pushSecondTernaryToken(token, opened_tag)
       
       closed_tag = @stanza.opened_tags.shift
       # closed_tag = @stanza.opened_tags.first

       # Also, reduce the number of opened tags for this line
       # @todo refactor
       @opened_tags.shift

       # attribMap = NB_MARKUP_TEI_MAP[closed_tag.name][token].values[0]
       # closed_tag[attribMap.keys[0]] = attribMap[attribMap.keys[0]]
       attribMap = NB_TERNARY_TOKEN_TEI_MAP[closed_tag.name][:secondary][token].values[0]
       closed_tag[attribMap.keys[0]] = attribMap[attribMap.keys[0]]

       # One cannot resolve the tag name and attributes until both tags have been fully parsed
       # closed_tag.name = NB_MARKUP_TEI_MAP[closed_tag.name][token].keys[0]
       closed_tag.name = NB_TERNARY_TOKEN_TEI_MAP[closed_tag.name][:secondary][token].keys[0]

       @current_leaf = @current_leaf.next = Nokogiri::XML::Node.new token, @teiDocument
       @has_opened_tag = true
       @opened_tag = @current_leaf

       @stanza.opened_tags.unshift @opened_tag
       @opened_tags.unshift @opened_tag
     end

     def pushInitialToken(token)

=begin
       @current_leaf = @current_leaf.add_child Nokogiri::XML::Node.new token, @teiDocument
       @has_opened_tag = true
       @opened_tag = @current_leaf
=end
       @current_leaf = BinaryNotaBeneDelta.new(token, @teiDocument, @current_leaf)
       @has_opened_tag = true
       @opened_tag = @current_leaf

       # puts "Opening a tag: #{@opened_tag.parent}"

       # @stanza.opened_tags << @opened_tag
       
       # Add the opened tag for the stanza and line
       # @todo refactor
       @stanza.opened_tags.unshift @opened_tag
       # @opened_tags.unshift @opened_tag

       # If the tag is not specified within the markup map, raise an exception
       #
     end

     # Deprecated
     # @todo Remove
     #
     def close(token, opened_tag)

       while not @stanza.opened_tags.empty? and NB_MARKUP_TEI_MAP.has_key? opened_tag.name and NB_MARKUP_TEI_MAP[opened_tag.name].has_key? token




         # This reduces the total number of opened tags within the stanza
         closed_tag = @stanza.opened_tags.shift

         # Also, reduce the number of opened tags for this line
         # @todo refactor
         # @opened_tags.shift

         # closed_tag = @opened_tags.shift
         # @stanza.opened_tags.shift

         # puts "Closing tag for line: #{closed_tag.name}..."

         # Iterate through all of the markup and set the appropriate TEI attributes
         attribMap = NB_MARKUP_TEI_MAP[closed_tag.name][token].values[0]
         closed_tag[attribMap.keys[0]] = attribMap[attribMap.keys[0]]

         # One cannot resolve the tag name and attributes until both tags have been fully parsed
         closed_tag.name = NB_MARKUP_TEI_MAP[closed_tag.name][token].keys[0]
         
         # logger.debug "Closed tag: #{closed_tag.name}"
         # logger.debug "Updated element: #{closed_tag.to_xml}"

         # @current_leaf = opened_tag.parent
         # @opened_tag = @stanza.opened_tags.first
         # @has_opened_tag = false
             
         # Continue iterating throught the opened tags for the stanza
         opened_tag = @stanza.opened_tags.first
       end

       return closed_tag
     end

     def closeStanza(token, opened_tag, closed_tag = nil)

=begin
       debugOutput = @stanza.opened_tags.map {|tag| tag.name }
       puts "Terminating a sequence #{debugOutput}"
       puts @stanza.elem.to_xml
=end

       # For terminal tokens, ensure that both the current line and preceding lines are closed by it
       # Hence, iterate through all matching opened tags within the stanza
       #
       while not @stanza.opened_tags.empty? and NB_MARKUP_TEI_MAP.has_key? opened_tag.name and NB_MARKUP_TEI_MAP[opened_tag.name].has_key? token

         # This reduces the total number of opened tags within the stanza
         closed_tag = @stanza.opened_tags.shift

         # Also, reduce the number of opened tags for this line
         # @todo refactor
         @opened_tags.shift

         closed_tag.close(token)
         
         # logger.debug "Closed tag: #{closed_tag.name}"
         # logger.debug "Updated element: #{closed_tag.to_xml}"

         # @current_leaf = opened_tag.parent
         # @opened_tag = @stanza.opened_tags.first
         # @has_opened_tag = false
             
         # Continue iterating throught the opened tags for the stanza
         opened_tag = @stanza.opened_tags.first
       end

       return closed_tag
     end

     def pushTerminalToken(token, opened_tag)

       # Throw an exception if this is not a "MDNM" Modecode
       if token != '«MDNM»'

         if opened_tag.name != '«FN1'

           @current_leaf.close '«MDNM»'

           @stanza.opened_tags.shift
           @opened_tags.shift

           @current_leaf = @current_leaf.parent
           
           pushInitialToken(token)

           # raise NotImplementedError.new "Cannot close the opened Modecode #{opened_tag.name} with the token: #{token}"
         else

           raise NotImplementedError.new "Attempting to parse the footnote #{opened_tag.name} closed with the token #{token} as a standard line"
         end
       else

         # First, retrieve last opened tag for the line
         # In all cases where there are opened tags on previous lines, there is an opened tag on the existing line
         #
         
         # puts "Current opened tags in the stanza: #{@stanza.opened_tags}" # @todo Refactor
         
         # @stanza.opened_tags << @opened_tag
         
         # @stanza.opened_tags = []
         # @has_opened_tag = false
         # @current_leaf = @stanza.opened_tags.last.parent
         
         # More iterative approach
         
         # opened_tag = @stanza.opened_tags.shift
         
         # closed_tag = close(token, opened_tag)
         # closeStanza(token, opened_tag, closed_tag)
         closed_tag = closeStanza(token, opened_tag)
         
         # puts @teiDocument
         # puts closed_tag
         
         # Once all of the stanza elements have been closed, retrieve the last closed tag for the line
         
         @current_leaf = closed_tag.parent
         # @opened_tag = @stanza.opened_tags.first
         
         # @has_opened_tag = false
         @has_opened_tag = !@opened_tags.empty?
         
       end
     end

     def push(token)
       
       # puts "Appending the following token to the line: #{token}"

       # If there is an opened tag...

       # First, retrieve last opened tag for the line
       # In all cases where there are opened tags on previous lines, there is an opened tag on the existing line
       #
       # opened_tag = @opened_tags.first
       opened_tag = @stanza.opened_tags.first

       # puts "Does this line have an opened tag? #{!opened_tag.nil?}"
       # puts "Name of the opened tag: #{opened_tag.name}" if opened_tag

       # Check to see if this is a terminal token for a ternary sequence
       # if opened_tag and NB_TERNARY_TOKEN_TEI_MAP.has_key? opened_tag.name and NB_TERNARY_TOKEN_TEI_MAP[opened_tag.name][:terminal].has_key? token

         # pushTermTernaryToken token, opened_tag

       # Check to see if this is a secondary token for a ternary sequence
       # elsif opened_tag and NB_TERNARY_TOKEN_TEI_MAP.has_key? opened_tag.name and NB_TERNARY_TOKEN_TEI_MAP[opened_tag.name][:secondary].has_key? token
       if opened_tag and NB_TERNARY_TOKEN_TEI_MAP.has_key? opened_tag.name and NB_TERNARY_TOKEN_TEI_MAP[opened_tag.name][:secondary].has_key? token

         raise NotImplementedError.new "Attempting to parse tokens as 'ternary tokens'"
         pushSecondTernaryToken token, opened_tag

       # Check to see if this is a terminal token
       elsif opened_tag and NB_MARKUP_TEI_MAP.has_key? opened_tag.name and NB_MARKUP_TEI_MAP[opened_tag.name].has_key? token

         pushTerminalToken token, opened_tag
         #
         # If there isn't an opened tag, but the current token appears to be a terminal token, raise an exception
         #
       elsif NB_MARKUP_TEI_MAP.has_key? @current_leaf.name and NB_MARKUP_TEI_MAP[@current_leaf.name].has_key? token

         raise NotImplementedError, "Failed to opened a tag closed by #{token}: #{@current_leaf.to_xml}"
         
         # If this is an initial token, open a new tag
         #
         # @todo Refactor
       elsif NB_MARKUP_TEI_MAP.has_key? token

         pushInitialToken token

       elsif NB_SINGLE_TOKEN_TEI_MAP.has_key? token

         pushSingleToken token
       else

         # puts NB_MARKUP_TEI_MAP.has_key? @opened_tag.name if @opened_tag
         # puts NB_MARKUP_TEI_MAP[@opened_tag.name].has_key? token.strip if @opened_tag and NB_MARKUP_TEI_MAP.has_key? @opened_tag.name
         # puts NB_MARKUP_TEI_MAP[@opened_tag.name].keys if @opened_tag and NB_MARKUP_TEI_MAP.has_key? @opened_tag.name

         # Terminal tokens are not being properly parsed
         # e. g. previous line had a token MDUL, terminal token MDNM present in the following
         # MDNM was not identified as a token

         # @current_leaf needs to be updated

         raise NotImplementedError, "Failed to parse the following as a token: #{token}" if /«/.match token

         # logger.debug "Appending text to the line: #{token}"
         
         pushText token

         debugOutput = @opened_tags.map { |tag| tag.name }
         # puts "Updated tags for the line: #{debugOutput}"

         raise NotImplementedError, "Failure to close a tag likely detected: #{@teiDocument.to_xml}" if @opened_tags.length > 16
       end
     end
   end
 end
