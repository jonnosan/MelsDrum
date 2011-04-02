#!/usr/bin/ruby

# dasm.rb
#
# == Synopsis
#
# RPC-4000 Disassembler
#
#

require 'rubygems'
require 'optparse'


options = {}
opts= OptionParser.new 
opts.banner = "Usage: dasm.rb [options] <filename.mel>"
#opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
#  options[:verbose] = v
#end
opts.parse!

filenames=ARGV
if filenames.length==0 then
	p opts.parse("-h")
	exit
end
