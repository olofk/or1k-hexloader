#r3 = byte
#r4 = tmp
#r5 = tmp
#r6 = BASEADDR
#r7 = ADDRESS
#r8 = tmp (in parseByte)
#r9 = Return address	
#r10 = tmp
#r11 = CNT
#r12 r9 shadowed	
.globl main
	.org 0x100
main:	
	l.movhi r0, 0
	l.jal uartInit
	l.nop
	l.jal findRecord
	# l.jal uartRead
	l.nop

	l.nop 0x1
	
err:
	l.nop 0x1
	l.nop 0x1
#r4 = UART Base address
#r5 = Register value
uartInit:
	l.movhi r4, hi(0x90000000)
	l.ori r4, r4, lo(0x90000000)

	# Set LCR = LCR_DLA
	l.addi r5, r0, 0x80
	l.sb 3(r4), r5

	# Set divisor 0x1B = 50MHz/(115200*16)
	l.addi r5, r0, 0x1b
	l.sb 0(r4), r5
	l.addi r5, r0, 0x0
	l.sb 1(r4), r5

	# Set line control register:
	# - 8 bits per character
	# - 1 stop bit
	# - No parity
	# - Break disabled
	# - Disallow access to divisor latch
	# LCR = LCR_BPS_8
	l.addi r5, r0, 0x3
	l.sb 3(r4), r5

	# Reset FIFOs and set trigger level to 14 bytes
	# REG8(FCR) = FCR_CLRRECV | FCR_CLRTMIT | FCR_TRIG_14;
	l.addi r5, r0, 0xc3
	l.sb 2(r4), r5

	# Disable all interrupts
	# REG8(IER) = 0;
	l.addi r5, r0, 0x0
	l.sb 1(r4), r5
	l.jr r9
	l.nop
	
#r8 = baseaddr
uartRead:
	l.movhi r8, hi(0x90000000)
	l.ori r8, r8, lo(0x90000000)

1:	l.lbz r3, 5(r8) #Read LSR
	l.andi r3, r3, 0x1 #Mask out Receiver ready
	l.sfeqi r3, 0
	l.bf 1b
	l.nop
	l.lbz r3, 0(r8) #Read word from UART to r3
	l.nop 0x2
	l.jr r9
	l.nop
	
#r4 = tmp
#r5 = tmp
setBaseAddress:
	l.jal parseByte
	l.slli r4, r3, 16
	l.jal parseByte
	l.slli r5, r3, 24
	l.or r6, r4, r5
	l.jr r9
	l.nop

#r4 = offset
#r5 = counter
#r10 = address
writeData:
	l.add r4, r6, r7 #Set start address
	l.movhi r5, 0    #Clear counter
1:	l.jal parseByte
	l.add r10, r4, r5 #address = start address + counter
	l.addi r5, r5, 1 #Increase counter
	l.sb 0(r10), r3
	l.sfeq r5, r10
	l.bnf 1b
	l.nop
	

findRecord:
	l.or r12, r9, r0 #Save return address to r12
	l.addi r3, r0, 48
1:	l.jal uartRead
	l.nop
	l.sfeqi r3, ':'
	l.nop 0x3
	l.bnf 1b
	l.nop
	l.jr r12
	l.nop

#Valid chars are 0-9 (0x30-0x39) and A-F (0x41-0x46)
parseByte:
	
	l.jal uartRead
	l.nop
	l.nop

	#Error if r3 < 0
	l.sfltui r3, '0'
	l.bf err
	l.nop

	#Next check if r3 > 9
	l.sfltui r3, '9'
	l.bf 1
	l.nop

	#If 0-9, subtract '0' and return
	l.addi r3, r3, -48
	l.jr r9
	l.nop

	#r3 is > 9 at this point
	#Error if r3 < A
1:	l.sfleui r3, 'A'
	l.bf err
	l.nop

	#Error if r3 > F
	l.sfleui r3, 'F'
	l.bnf err
	l.nop

	#If A-F subtract ('A'-10) and return
	l.addi r3, r3, -55
	l.jr r9
