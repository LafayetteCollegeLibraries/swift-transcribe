# -*- coding: utf-8 -*-
require_relative '../spec_helper'

describe 'TeiParser' do

  before :each do

    @nb_store_path = '/usr/share/spp/ruby-tools/spp/master'
  end

  @nb_store_path = '/usr/share/spp/ruby-tools/spp/master'

  # Dir.glob("#{@nb_store_path}/06E2/*").select {|path| not /tocheck/.match(path) and not /PUMP/.match(path) and not /ANOTHER/.match(path) }.each do |file_path|
  # Dir.glob("#{@nb_store_path}/06E2/553E06E2").select {|path| not /tocheck/.match(path) and not /PUMP/.match(path) and not /ANOTHER/.match(path) }.each do |file_path|
  Dir.glob("#{@nb_store_path}/06E2/132-06E2").select {|path| not /tocheck/.match(path) and not /PUMP/.match(path) and not /ANOTHER/.match(path) }.each do |file_path|

    it "parses the Nota Bene document #{file_path}" do

      expect {

        @parser = SwiftPoetryProject::TeiParser.new "#{file_path}"
        puts @parser.parse.to_xml
      }.to_not raise_error
    end

    it "parses Nota Bene tokens" do
      
      @parser = SwiftPoetryProject::TeiParser.new "#{file_path}"
      expect(@parser.parse.to_xml).not_to match(/«MD..»/)
    end
  end
end
