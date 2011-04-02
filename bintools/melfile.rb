#!/usr/bin/ruby
#
# routines for manipulating ".mel" files, which represent a snapshot of an RPC-4000 magnetic drum.
# format described in https://github.com/jonnosan/MelsDrum/blob/master/doc/file_formats.txt
#

class MelFile
	attr_accessor	:version,:description

	def initialize(filename=nil)
		@version=1
		@data=Array.new(8008,0)
	end
	
	def to_s
		header+packed_data
	end
	def header
		[".mel","01",description,0x1a].pack("A4A2A256c1")
	end
	def packed_data
		@data.pack("N*")
	end

	def setword(address,value)
		@data[get_offset(address)]=value
	end
	
	def getword(address)
		@data[get_offset(address)]
	end


	def get_offset(address)
		track=address/100
		sector=address % 100
		raise "invalid address #{address}" unless (0..127).include?(track) && (0..63).include?(sector)			
		case track
			when 0..124 then track*64+sector
			when 125 then 123*64+((sector-16)%64)
			when 126 then 124*64+((sector-24)%64)
			when 127 then 125*64+(sector%8)
		end
	end
end

