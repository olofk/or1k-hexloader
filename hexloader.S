#r3 = byte
#r4 = tmp
#r5 = tmp
#r6 = BASEADDR
#r7 = ADDRESS
#r8 = tmp (in parseByte)
#r9 = Return address	
#r10 = tmp
#r11 = CNT
	
#r4 = tmp
#r5 = tmp
setBaseAddress:
	l.j parseByte
	l.slli r4, r3, 16
	l.j parseByte
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
1:	l.j parseByte
	l.add r10, r4, r5 #address = start address + counter
	l.addi r5, r5, 1 #Increase counter
	l.sb 0(r10), r3
	l.sfeq r5, r10
	l.bnf 1b
	l.nop
	

findRecord:
1:	l.j parseByte
	l.sfeqi r3, ':'
	l.bnf 1b
	l.nop

#Valid chars are 0-9 (0x30-0x39) and A-F (0x41-0x46)
parseByte:
	l.movhi r8, 0x9000
	l.ori r8, 0000
	l.lb r3, 0(r8) #Read word from UART
	l.nop

	#Error if < 0
	l.sflti r3, '0'
	l.j err
	l.nop

	#Next check if > 9
	l.sflti r3, ':'
	l.bf 1
	l.nop

	#If 0-9, subtract '0' and return
	l.sub r3, r3, '0'
	l.jr r9
	l.nop
