#!/usr/bin/ruby
#
# routines for manipulating ".mel" files, which represent a snapshot of an RPC-4000 magnetic drum.
# format described in https://github.com/jonnosan/MelsDrum/blob/master/doc/file_formats.txt
#



RPC400_OPCODES={
	:hlt=>['halt',00,:none],
	:sns=>['read sense switches)',0,:data],
	:cxe=>['compare index equal',1,:data],
	:rau=>['reset and add to upper',2,:address],
	:ral=>['reset and add to lower',3,:address],
	:sau=>['store address from upper',4,:address],
	:mst=>['masked store',5,:address],
	:ldc=>['load count',6,:address],
	:ldx=>['load index',7,:data],
	:inp=>['input',8,:data],
	:exc=>['exchange',9,:data],
	:dvu=>['divide by upper',10,:address],
	:div=>['divide',11,:address],
	:srl=>['shift right or left',12,:data],
	:slc=>['shift left and count',13,:data],
	:mpy=>['multiply',14,:address],
	:mpt=>['multiply by ten',15,:data],
	:prd=>['print from address',16,:data],
	:pru=>['print from upper',17,:data],
	:ext=>['extract',18,:data],
	:mml=>['masked merge lower',19,:address],
	:cme=>['compare memory equal',20,:address],
	:cmg=>['compare memory greater',21,:address],
	:tmi=>['transfer on minus',22,:address],
	:tbc=>['transfer on branch control',23,:address],
	:stu=>['store upper',24,:address],
	:stl=>['store lower',25,:address],
	:clu=>['clear upper',26,:address],
	:cll=>['clear lower',27,:address],
	:adu=>['add to upper',28,:address],
	:adl=>['add to lower',29,:address],
	:sbu=>['subtract from upper',30,:address],
	:sbl=>['subtract from lower',31,:address],

}

class RPC4000Instruction
	attr_accessor :opcode,:data,:next_address,:index_tag
	attr_reader	:instruction_word
	def initialize(word)
		@instruction_word=word
		raise "#{word} can't be decoded as an RPC-4000 instruction word " unless word>=0 && word<0x100000000
		opcode_bits=word>>27
		@data=(word>>14) % 0x2000
		@next_address=(word>>1) % 0x2000
		index_tag_bit=word % 2
		if opcode_bits==0 then
			@opcode=(data==0 ? :hlt : :sns)
		else
			RPC400_OPCODES.keys.each do |o|
				@opcode=o if opcode_bits==RPC400_OPCODES[o][1]
			end
		end		
	end

	def data_address
		data_track= data>>6
		data_sector=data % 64
		"%03d/%02d" % [data_track,data_sector]
	end
		
	def to_s
		d=case RPC400_OPCODES[@opcode][2]
			when :none then ""
			when :data then ("0x%X" % (data))
			when :address then data_address
		else
			raise "unknown opcode type #{RPC400_OPCODES[@opcode][2]}"
		end
		n=("%03d/%02d" % [next_address/100,next_address % 100])
		"#{"%08X" % instruction_word}\t#{@opcode.to_s.upcase}\t#{d}\t#{n}\t#{RPC400_OPCODES[@opcode][0]}"		
	end
	
end



class MelFile
	attr_accessor	:version,:description

	def initialize(filename=nil)
		@version=1
		@data=Array.new(8008,0)
		return if filename.nil?
		raise "invalid filename - #{filename} " unless File.file?(filename)
		filebytes=File.open(filename,"rb").read
		expected_file_length=self.to_s.length
		raise ("#{filename} is not a vald .mel file (was %d bytes, should be %d bytes)" % [filebytes.length,expected_file_length]) unless filebytes.length==expected_file_length
		raise "#{filename} is not a vald .mel file (bad signature)" unless filebytes[0,6]==".mel01"
		@description=filebytes[06,255].strip
		@data=filebytes[263,8008*4].unpack("N*")
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

	def setword(track,sector,value)
		@data[get_offset(track,sector)]=value
	end
	
	def getword(track,sector)
		@data[get_offset(track,sector)]
	end
	
	def to_listing
		s=""
		128.times do |track|
			64.times do |sector|
				next if [123,124].include?(track)
				s+="%03d/%02d\t#{RPC4000Instruction.new(getword(track,sector))}\n" % [track,sector]
			end
		end
		s
	end

private
	def get_offset(track,sector)
		raise "invalid address #{track}/#{sector}" unless (0..127).include?(track) && (0..63).include?(sector)			
		case track
			when 0..124 then track*64+sector
			when 125 then 123*64+((sector-16)%64)
			when 126 then 124*64+((sector-24)%64)
			when 127 then 125*64+(sector%8)
		end
	end
end

