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
		assert_raise(RuntimeError) {  mel.setword(12364,4) } #invalid address
		assert_raise(RuntimeError) {  mel.setword(-1,4) }	#invalid address
		assert_raise(RuntimeError) {  mel.setword(12800,0) } #invalid address
		

		assert_equal(0,mel.getword(00000),"drum values should be 0 on init")
		assert_equal(0,mel.getword(12763),"drum values should be 0 on init")

		mel.setword(10000,2)
		mel.setword(10063,5)
	
		assert_equal(2,mel.getword(10000))
		assert_equal(5,mel.getword(10063))

		mel.setword(12301,8)
		mel.setword(12463,9)
		mel.setword(12701,11)

		assert_equal(8,mel.getword(12301))
		assert_equal(8,mel.getword(12517))
		
		assert_equal(9,mel.getword(12463))
		assert_equal(9,mel.getword(12623))
		assert_equal(11,mel.getword(12701))
		assert_equal(11,mel.getword(12709))
		assert_equal(11,mel.getword(12749))

		filename="test1.mel"
		File.open(filename,"wb")<<mel
		
		mel2=MelFile.new
		128.times do |track|
			64.times do |sector|
				mel2.setword(track*100+sector,track)
			end
		end



		File.open("test2.mel","wb")<<mel2
		
		128.times do |track|
			64.times do |sector|
				next if [123,124].include?(track)
				address=track*100+sector
				assert_equal(track,mel2.getword(address))
			end
		end


	end
end