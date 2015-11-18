
The 1st line of the LCD will display "DRAGON12 TRAINER" after power up, 
but you can customize it with your name, school name or anything else you would like. 

The benefit of displaying your name is that your board won't be accidentally swapped with 
your classmate's board when you work in your school lab.

To customize it:
   1. Open the file named First_line.asm with AsmIDE
   2. Replace the DRAGON12 TRAINER with whatever 16 charcters that you would like to display.
   3. Assemble the First_line.asm to generate First_line.s19.
   3. Use LOAD command in AsmIDE to download the First_line.s19 into EEPROM
   4. After download, press the reset button to update the LCD display.

Warning:
The content at $0FFD gets copied into BPROT ($114) upon reset 
Be careful not to adversely write anything at $0FFD to write-protect EEPROM 
or you may have to use a BDM to unprotect it.

