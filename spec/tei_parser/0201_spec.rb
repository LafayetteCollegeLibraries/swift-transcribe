# -*- coding: utf-8 -*-
require_relative '../spec_helper'

describe 'TeiParser' do

  before :each do

    @nb_store_path = '/var/lib/spp/master'
  end

  @nb_store_path = '/var/lib/spp/master'

  Dir.glob("#{@nb_store_path}/0201/*").select {|path| not /tocheck/.match(path) and not /PUMP/.match(path) }.each do |file_path|
  # Dir.glob("#{@nb_store_path}/0201/640-0201").select {|path| not /tocheck/.match(path) and not /PUMP/.match(path) }.each do |file_path|
  # Dir.glob("#{@nb_store_path}/0201/866-0201").select {|path| not /tocheck/.match(path) and not /PUMP/.match(path) }.each do |file_path|

    it "parses the Nota Bene document #{file_path}" do

      puts file_path

      expect {

        @parser = SwiftPoetryProject::TeiParser.new "#{file_path}"
        @parser.parse.to_xml
      }.to_not raise_error
    end

=begin
    it "parses «MDUL» tokens" do
      
      # file_path = "#{file_path}/0201/391-0201"
      @parser = SwiftPoetryProject::TeiParser.new "#{file_path}"
      expect(@parser.parse.to_xml).not_to match(/«MDUL»/)
    end
=end
  end
end
