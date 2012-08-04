#!/usr/bin/env ruby

require "wiringpi"
@io = WiringPi::GPIO.new(WPI_MODE_GPIO)

@datapin   = 4  # DI
@latchpin  = 17 # LI
@enablepin = 21 # EI
@clockpin  = 22 # CI
#long @sb_CommandPacket
#int @sb_CommandMode
#int @sb_BlueCommand
#int @sb_RedCommand
#int @sb_GreenCommand

def delay(ms)
  sleep ms * 0.001
end

def setup()
   @io.mode(@datapin, OUTPUT)
   @io.mode(@latchpin, OUTPUT)
   @io.mode(@enablepin, OUTPUT)
   @io.mode(@clockpin, OUTPUT)

   @io.write(@latchpin, LOW)
   @io.write(@enablepin, LOW)
   puts "setup complete"
end

def set_rgb(r,g,b)
    @sb_RedCommand = r # Maximum red
    @sb_GreenCommand = g # Minimum green
    @sb_BlueCommand = b # Minimum blue
    sb_SendPacket()
end

def sb_SendPacket()
   @sb_CommandPacket = @sb_CommandMode & 0b11
   @sb_CommandPacket = (@sb_CommandPacket << 10)  | (@sb_BlueCommand  & 1023)
   @sb_CommandPacket = (@sb_CommandPacket << 10)  | (@sb_RedCommand   & 1023)
   @sb_CommandPacket = (@sb_CommandPacket << 10)  | (@sb_GreenCommand & 1023)
   #puts "@sb_CommandPacket: #{@sb_CommandPacket.to_s(2)}"

   s1 = 0b11111111_00000000_00000000_00000000
   s2 = 0b00000000_11111111_00000000_00000000
   s3 = 0b00000000_00000000_11111111_00000000
   s4 = 0b00000000_00000000_00000000_11111111
   @io.shiftOut(@datapin, @clockpin, MSBFIRST, (s1 & @sb_CommandPacket) >> 24)
   @io.shiftOut(@datapin, @clockpin, MSBFIRST, (s2 & @sb_CommandPacket) >> 16)
   @io.shiftOut(@datapin, @clockpin, MSBFIRST, (s3 & @sb_CommandPacket) >> 8)
   @io.shiftOut(@datapin, @clockpin, MSBFIRST, (s4 & @sb_CommandPacket))

   delay(5) # adjustment may be necessary depending on chain length
   @io.write(@latchpin,HIGH) # latch data into registers
   delay(5) # adjustment may be necessary depending on chain length
   @io.write(@latchpin,LOW)
end

def main
  setup
  loop do
    @sb_CommandMode = 0b01 # Write to current control registers
    set_rgb 127, 127, 127 # Full current
    sb_SendPacket()

    @sb_CommandMode = 0b00 # Write to PWM control registers
    set_rgb 0, 0, 0
    sb_SendPacket()
    delay(900)
    
    @sb_CommandMode = 0b00 # Write to PWM control registers
    set_rgb 1023, 0, 0 # Maximum red
    6.times { sb_SendPacket() }
    delay(100)
#next
    @sb_CommandMode = 0b00 # Write to PWM control registers
    set_rgb 0, 1023, 0 # Maximum green
    6.times { sb_SendPacket() }
    delay(100)

    @sb_CommandMode = 0b00 # Write to PWM control registers
    set_rgb 0, 0, 1023 # Maximum blue
    6.times { sb_SendPacket() }
    delay(100)
  end
end

main
