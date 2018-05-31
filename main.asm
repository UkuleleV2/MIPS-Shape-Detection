#		ECOAR LAB - MIPS PROJECT						#
#		Micha³	Kamiñski
#		Determining shape								#


.data

buffer:		.space 	2 				# for proper header alignment in data section
header: 	.space 	54				# the bmp file header size
width:		.word	320				# header+18
height:		.word	240				# header+22

inputMsg:	.asciiz "Enter the file name: "
shape1string:	.asciiz "Shape 1\n"
shape2string:	.asciiz "Shape 2\n"
NameOfFile:	.space	128

errorMsg:	.asciiz	"Descriptor error. Program restarting.\n"
bitmapMsg: 	.asciiz "The file entered is not a bitmap. Program restarting.\n"
formatMsg:	.asciiz	"The file entered is a bitmap, but is not 24-bit. Program restarting.\n"
sizeMsg:	.asciiz	"The file has wrong width . Program restarting.\n"


.text
main:
	# begin the program, print prompt
	li	$v0, 4					# syscall-4 print string
	la	$a0, inputMsg				# load address of the input msg
	syscall

	# read the input file name
	li 	$v0, 8					# syscall-8 read string
	la	$a0, NameOfFile				# load address of the NameOfFile
	li 	$a1, 128				# load the maximum number of characters to read
	syscall

	# cut the '\n' from the NameOfFile
	move	$t0, $zero				# load 0 to $t0 to make sure that it starts from the beginning of the string
	li	$t2, '\n'				# load the '\n' character to the $t2 register

	# find the '\n'
findN:
	lb	$t1, NameOfFile($t0)			# read the NameOfFile 
	beq	$t1, $t2, removeN			# check if '\n'
	addi 	$t0, $t0, 1				
	j 	findN

	# remove the '\n', swap with '\0'
removeN:
	li	$t1, '\0'				# replace '\n' with '\0'
	sb	$t1, NameOfFile($t0)

	# open input file for reading
	li	$v0, 13					# syscall-13 open file
	la	$a0, NameOfFile				# load filename address
	li 	$a1, 0					# 0 flag for reading the file
	li	$a2, 0					# mode 0
	syscall
							# $v0 contains the file descriptor
	bltz	$v0, fileError				# if $v0=-1, there is a descriptor error, go to fileError
							# and the file cannot be read
	move	$s0, $v0				# save the file descriptor from $v0 for closing the file

	# read the header data
	li	$v0, 14					# syscall-14 read from file
	move	$a0, $s0				# load the file descriptor
	la	$a1, header				# load header address to store
	li	$a2, 54					# read first 54 bytes of the file
	syscall

	# check if our file is a bitmap
	li	$t0, 0x4D42 				# 0X4D42 is the signature for a bitmap (hex for "BM")
	lhu	$t1, header				# the signature is stored in the first two bytes (header+0)
							# lhu - load halfword unsigned - loads the first 2 bytes into $t1 register
	bne	$t0, $t1, bitmapError  			# if these two aren't equal then the input is not a bitmap

	# check if it is the right size
	lw	$t0, width				# width (320) = $t0
	lw 	$s1, header+18				# read the file width from the header information (offset of 18) - need to read only 2 bytes
	bne	$t0, $s1, sizeError			# if not equal, go to sizeError
	lw	$t0, height				# height (240) = $t0
	lw	$s2, header+22				# read the file height from the header information (offset of 22) - need to read only 2 bytes
	bne	$t0, $s2, sizeError			# if not equal, go to sizeError

	# confirm that the bitmap is actually 24 bits
	li	$t0, 24					# store 24 into $t0, because it is a 24-bit bitmap (uncompressed)
	lb	$t1, header+28				# offset of 28 points at the header's indication of how many bits the bmp is
							# (size of 2 bytes, we only need the first one)
	bne	$t0, $t1, formatError			# if the two aren't equal, it means the entered file is not a 24 bit bmp, go to formatError

	# Everything seems ok, lets move forward
	lw	$s3, header+34				# store the size of the data section of the image

	# read image data into array - allocationg heap memory
	li	$v0, 9					
	move	$a0, $s3				
	syscall						
	move	$s4, $v0				

	li	$v0, 14					# syscall-14, read from file
	move	$a0, $s0				# load the file descriptor
	move	$a1, $s4				# load base address of array
	move	$a2, $s3				# load size of data section
	syscall

	# close the file
closeFile:
	li	$v0, 16					# syscall-16 close file
	move	$a0, $s0				
	syscall

#----------------------------------MAIN PROGRAM--------------------------------------#


SetUp:
	move	$t3, $s4				# load base address of the image
	li	$t4, 0					# Position of first column of black image in
	move	$t6, $s1				# width offset
	mul	$t6, $t6, 3				# multiply to get the number of BGR threes in a row
	li	$t7, 0					# 


lookforblack:
	lb 	$t0, ($t3)
	beqz	$t0,blackappeared
	add	$t3, $t3, 3	
	j	lookforblack
	
blackappeared:
	move	$t4,$t3 # start of black block - t5
widthofblack:
	lb 	$t0, ($t3)
	bnez 	$t0, pre
	add	$t3, $t3, 3
	j	widthofblack
	
pre:	#t4 - beginning of block, t7 - end of block
	add	$t4,$t4,$t6
	sub	$t3, $t3, 3		
	move	$t7,$t3
	add	$t7,$t7,$t6
	move	$t3,$t4	#next row in black box
loopblack:
	lb 	$t0, ($t3)		
	beq	$t3,$t7,nextrow
	bnez	$t0,foundwhite
	add	$t3, $t3, 3
	j	loopblack
nextrow:
	add	$t7,$t7,$t6
	add	$t4,$t4,$t6
	move	$t3,$t4
	j	loopblack
foundwhite:
	sub	$t3,$t3,3
checkingshape:
	lb 	$t0, ($t3)
	bnez	$t0, shape1
	add	$t3,$t3,3
	lb 	$t0, ($t3)
	beqz	$t0, shape2
	
	sub	$t3,$t3,3
	add	$t3,$t3,$t6
	j	checkingshape

shape1:
	li	$v0, 4					# syscall-4 print string
	la	$a0, shape1string			
	syscall
	j 	end

shape2:
	li	$v0, 4					# syscall-4 print string
	la	$a0, shape2string			
	syscall

#----------------------- THE END OF MAIN----------------------------#			


	# end the program
end:
	li 	$v0, 10					# syscall-10 exit
	syscall


	# print file error message
fileError:
	li	$v0, 4					# syscall-4 print string
	la	$a0, errorMsg				
	syscall
	j	main					# restart the program

	# print bitmap error message
bitmapError:
	li	$v0, 4					# syscall-4 print string
	la	$a0, bitmapMsg				
	syscall
	j	main					# restart the program

	# print format error message
formatError:
	li	$v0, 4					# syscall-4 print string
	la	$a0, formatMsg				
	syscall
	j	main					# restart the program

	# print size error message
sizeError:
	li	$v0, 4					# syscall-4 print string
	la	$a0, sizeMsg				
	syscall
	j	main					# restart the program
