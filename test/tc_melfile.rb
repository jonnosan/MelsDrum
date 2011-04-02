#!/usr/bin/ruby

#make sure the relevant folder with our libraries is in the require path
lib_path=File.expand_path(File.dirname(__FILE__)+"//..//bintools")
$:.unshift(lib_path) unless $:.include?(lib_path)

require 'test/unit'
require 'melfile'
class MelFileTests < Test::Unit::TestCase

	def test_basics
		mel=MelFile.new
		assert_equal(1,mel.version)
		test_description="this is a sample .mel file, created at #{Time.now}"
		mel.description=test_description
		assert_equal(test_description,mel.description)
		assert_raise(RuntimeError) {  mel.setword(123,64,4) } #invalid address
		assert_raise(RuntimeError) {  mel.setword(-1,1,4) }	#invalid address
		assert_raise(RuntimeError) {  mel.setword(128,00,0) } #invalid address
		

		assert_equal(0,mel.getword(000,00),"drum values should be 0 on init")
		assert_equal(0,mel.getword(127,63),"drum values should be 0 on init")

		mel.setword(100,00,2)
		mel.setword(100,63,5)
	
		assert_equal(2,mel.getword(100,00))
		assert_equal(5,mel.getword(100,63))

		mel.setword(123,01,8)
		mel.setword(124,63,9)
		mel.setword(127,01,11)

		assert_equal(8,mel.getword(123,1))
		assert_equal(8,mel.getword(125,17))
		
		assert_equal(9,mel.getword(124,63))
		assert_equal(9,mel.getword(126,23))
		assert_equal(11,mel.getword(127,1))
		assert_equal(11,mel.getword(127,9))
		assert_equal(11,mel.getword(127,49))


		filename="test1.mel"
		File.open(filename,"wb") {|f| f<<mel}

		assert_raise(RuntimeError) { mel2=MelFile.new("not_valid_filename") }
		assert_raise(RuntimeError) { mel2=MelFile.new(__FILE__) }

		mel2=MelFile.new(filename)
		assert_equal(test_description,mel2.description)
		assert_equal(9,mel2.getword(124,63))
		assert_equal(9,mel2.getword(126,23))
		assert_equal(11,mel2.getword(127,1))
		assert_equal(11,mel2.getword(127,9))
		assert_equal(11,mel2.getword(127,49))
		
		

		mel3=MelFile.new
		128.times do |track|
			64.times do |sector|
				mel3.setword(track,sector,track<<25)
			end
		end
		
		128.times do |track|
			64.times do |sector|
				next if [123,124].include?(track)
				assert_equal(track,mel3.getword(track,sector)>>25)
			end
		end
		
		puts mel3.to_listing

	end
	
	def test_dasm
		assert_equal(:sbl,RPC4000Instruction.new(0xFFFFFFFF).opcode)		
		assert_equal(:hlt,RPC4000Instruction.new(0x00000000).opcode)
		assert_equal(:sns,RPC4000Instruction.new(0x00010000).opcode)
		puts RPC4000Instruction.new(0x00010000)
		puts RPC4000Instruction.new(0x0)
		32.times do |i|
			op=(i<<27)+0b101010101010101010101010101
			puts RPC4000Instruction.new(op)
		end

	end
end