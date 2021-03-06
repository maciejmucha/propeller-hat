CON
  _CLKMODE = xtal1 + pll16x
  _XINFREQ = 6_000_000 
  
  ERR_PIN_RANGE = %000_000_00
  ERR_PIN_OK    = %000_000_01
  FW_VERSION    = %111_00001

OBJ
  serial : "FullDuplexSerial"
  
VAR
  byte packet
  byte cmd
  byte data
  
  byte lastA
  byte lastB
  byte lastC
  byte lastD
  byte lastE
  byte lastF
  
  byte bankA
  byte bankB
  byte bankC
  byte bankD
  byte bankE
  byte bankF

PUB main | rx, act
  
  ' Message Format
  ' --------------------------------------------------------------------
  ' 000 00000
  ' CMD DATA
 
 
  ' Propeller to Host
  ' --------------------------------------------------------------------
  ' 000 error condition
  ' 
  '   0 - pin out of range
  '   1 - OK
  ' 
  ' 001 to 110 port status update, lowest 5 bits contain pin state data
  ' 
  '   001 - port A [0..4]
  '   010 - port A [5..9]
  '   011 - port A [10..14]
  '   100 - port A [15..19]
  '   101 - port A [20..25]
  '   110 - port A [25..29]
  '   
  ' 111 version information
 
 
  ' Host to Propeller
  ' ---------------------------------------------------------------------
  ' 
  ' 000 - Act on port direction
  ' 010 - Act on port state
  ' 
  ' 00X - Value to write
  ' 
  ' Examples:
  ' 
  ' 011 - Write port HIGH
  ' 010 - Write port LOW
  ' 001 - Write port OUTPUT
  ' 000 - Write port INPUT
  ' 
  ' 1XX apply settings to pins indicated by 8 byte mask
  ' 
  ' 00000 to 11101 - Port 0 to 29
  

  serial.start( 31, 30, 0, 115200 )
  
  waitcnt(cnt + clkfreq)
  
  'Transmit firmware version
  serial.Tx(FW_VERSION)
  
  dira[0..29] := 0
  outa[0..29] := 0
  
  ' Send pin state in 6 bytes, each including 5 pins
  
  repeat
    rx := serial.RxCheck
    if rx > -1
      packet := rx
      cmd    := packet >> 5
      data   := packet & %000_11111
      
      if (cmd & %100) > 0
        serial.Tx(FW_VERSION)
      elseif data < 30
        act := (cmd & %010) >> 1
        if act ' Change port state
          outa[data] := (cmd & %001)
        else   ' 
          dira[data] := (cmd & %001)
          
        serial.Tx(ERR_PIN_OK | (dira[data] << 4) | (outa[data] << 3))
      else
        serial.Tx(ERR_PIN_RANGE)
  
    ' Return port status as 6 bytes of 000 + 5 pins
    ' Ignore pins which aren't set to inputs
    bankA := (ina[0..4]   & (dira[0..4]   ^ %000_11111 )) | %001_00000
    bankB := (ina[5..9]   & (dira[5..9]   ^ %000_11111 )) | %010_00000
    bankC := (ina[10..14] & (dira[10..14] ^ %000_11111 )) | %011_00000
    bankD := (ina[15..19] & (dira[15..19] ^ %000_11111 )) | %100_00000
    bankE := (ina[20..24] & (dira[20..24] ^ %000_11111 )) | %101_00000
    bankF := (ina[25..29] & (dira[25..29] ^ %000_11111 )) | %110_00000
 
    if bankA <> lastA
      serial.Tx(bankA)
      lastA := bankA
      
    if bankB <> lastB
      serial.Tx(bankB)
      lastB := bankB
      
    if bankC <> lastC
      serial.Tx(bankC)
      lastC := bankC
      
    if bankD <> lastD
      serial.Tx(bankD)
      lastD := bankD
      
    if bankE <> lastE
      serial.Tx(bankE)
      lastE := bankE
      
    if bankF <> lastF
      serial.Tx(bankF)
      lastF := bankF
      