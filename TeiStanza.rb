# -*- coding: utf-8 -*-

module SwiftPoemsProject

  POEM = 0
  LETTER = 1
  POEM_ID_PATTERN = /\d\d\d\-[0-9A-Z\!\-]{4}/

    NB_MARKUP_TEI_MAP = {
      
      '«MDUL»' => {
        
        '«MDNM»' => { 'hi' => { 'rend' => 'underline' } }
      },
      
      '«MDBO»' => {
        
        #'«MDNM»' => { 'hi' => { 'rend' => 'bold' } }
        '«MDNM»' => { 'hi' => { 'rend' => 'black-letter' } }
      },
      
      # "These Guidelines make no binding recommendations for the values of the rend attribute; the characteristics of visual presentation vary too much from text to text and the decision to record or ignore individual characteristics varies too much from project to project. Some potentially useful conventions are noted from time to time at appropriate points in the Guidelines. The values of the rend attribute are a set of sequence-indeterminate individual tokens separated by whitespace."
    # http://www.tei-c.org/release/doc/tei-p5-doc/en/html/ref-att.global.html#tei_att.rend

      '«MDBR»' => {

        '«MDNM»' => { 'hi' => { 'rend' => 'SMALL-CAPS-ITALICS' } }
      },

      '«MDBU»' => {

        #'«MDNM»' => { 'hi' => { 'rend' => 'bold underline' } }
        # NOTE: This is not within the standard TEI (?)
        # (Formerly "special-state")
        '«MDNM»' => { 'hi' => { 'rend' => 'black-letter' } },
        '«MDUL»' => { 'hi' => { 'rend' => 'black-letter' } }
      },

      '«MDDN»' => {
        
        '«MDNM»' => { 'hi' => { 'rend' => 'strikethrough' } }
      },
      
      '«MDRV»' => {

        '«MDNM»' => { 'hi' => { 'rend' => 'display-initial' } },
        '«MDUL»' => { 'hi' => { 'rend' => 'italic-display-initial' } }
      },

      '«MDSD»' => {

        #'«MDNM»' => { 'hi' => { 'rend' => 'subscript' } }
        '«MDNM»' => { 'hi' => { 'rend' => 'SMALL-CAPS' } }
      },

      # Source: 
      
      '«MDSU»' => {
        
        '«MDNM»' => { 'hi' => { 'rend' => 'sup' } },
        '«MDBU»' => { 'hi' => { 'rend' => 'sup' } }
      },

      # For footnotes
      '«FN1·' => {
        
        '»' => { 'note' => { 'place' => 'foot' } },
        '.»' => { 'note' => { 'place' => 'foot' } }
      },

      # Additional footnotes
      '«FN1' => {
        
        '»' => { 'note' => { 'place' => 'foot' } }
      },

      # Additional footnotes
      '«FN1«MDNM»' => {
        
        '»' => { 'note' => { 'place' => 'foot' } }
      },

      # For deltas
      # The begin-center (FC, FL) delta
      '«FC»' => {
      
        '«FL»' => { 'head' => {} }
      },

      # The end-of-center (FL, FL) delta
      '«FL»' => {
      
        '«FL»' => { 'head' => {} }
      },

      # The flush right (FR, FL) delta
      '«FR»' => {
        
        '«FL»' => { 'head' => {} }
    },

    # <gap>
    'om' => {

      '.' => { 'gap' => {} }
    }
  }

  NB_CHAR_TOKEN_MAP = {
      
    /\\ae\\/ => 'æ',
    /\\AE\\/ => 'Æ',
    /\\oe\\/ => 'œ',
    /\\OE\\/ => 'Œ',
    /``/ => '“',
    /''/ => '”',
    /(?<!«MDNM»|«FN1)·/ => ' ',
    /─ / => '─'    
  }

  class TeiStanza

    attr_reader :document, :elem
    attr_accessor :opened_tags

    def initialize(workType, poemElem, index, options = {})

      @workType = workType
       
      @poemElem = poemElem
      @teiDocument = @poemElem.document
      @document = @teiDocument
       
      # Depending upon whether or not this work is a poem, this shall alter the name of the element containing the stanza
      @blockElemName = @workType == POEM ? 'lg' : 'div'
      @elem = Nokogiri::XML::Node.new @blockElemName, @teiDocument
      @elem['n'] = index.to_s

      @opened_tags = options[:opened_tags] || []
      @line_has_opened_tag = options[:line_has_opened_tag] || !@opened_tags.empty?

      @poemElem.add_child(@elem)

#      # If there is an open tag...
#      if @line_has_opened_tag

      # If there is an open tag...
      if not @opened_tags.empty?

        # lineElem = TeiLine.new @workType, self, { :has_opened_tag => @line_has_opened_tag, :opened_tag => @opened_tags.last }
        lineElem = TeiLine.new @workType, self, { :opened_tags => Array.new(@opened_tags) }
      else

        lineElem = TeiLine.new @workType, self
      end

      @lines = [ lineElem ]
    end

    def pushLine

      # lineElem = @lines.last
      # lineElem['n'] = getLineIndex line

      # Remove the line index from the beginning of the line
      # line.sub!(/\d+  /, '')

      puts "New line - previous line: #{@lines.last.elem.to_xml}"
      puts "does the previous line have an opened tag? #{@lines.last.has_opened_tag}"

      if @lines.last.has_opened_tag

        # raise NotImplementedError, "A Nota Bene tag was not properly closed: #{@lines.last.elem.to_xml}"
        
        # Assumes a depth of 1 from <l> element
        # newLine.elem.add_child Nokogiri::XML::Node.new @lines.last.current_leaf.name, @document

        # @opened_tags << @lines.last.opened_tag
        nil
      end

=begin
      opened_tags = []
      opened_tags = [ @lines.last.opened_tag ] if @lines.last.opened_tag

      newLine = TeiLine.new(@workType, self, { :has_opened_tag => @lines.last.has_opened_tag, :opened_tags => opened_tags })
=end

      # newLine = TeiLine.new(@workType, self, { :has_opened_tag => @lines.last.has_opened_tag, :opened_tag => @lines.last.opened_tag })

      puts "Adding the following for a new line: #{@opened_tags}"

      newLine = TeiLine.new @workType, self, { :opened_tags => Array.new(@opened_tags) }

      @lines << newLine
    end

    def push(token)

       if @lines.length == 1 and @lines.last.elem.content.empty?

         token = token.sub POEM_ID_PATTERN, ''
         @lines.last.push token
       else

         # Trigger a new line
         if POEM_ID_PATTERN.match token

           pushLine
           token = token.sub POEM_ID_PATTERN, ''
         end

         token = token.sub /\r/, ''

         puts "new line token: #{token}"

         @lines.last.push token
       end
     end
   end
end
