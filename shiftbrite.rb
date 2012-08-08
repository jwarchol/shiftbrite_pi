#!/usr/bin/env ruby

require "wiringpi"
@io = WiringPi::GPIO.new(WPI_MODE_GPIO)
@interrupted = false
trap("INT") { puts "Interupt received"; @interrupted = true }
@debug = false

@datapin   = 4  # DI
@latchpin  = 17 # LI
@enablepin = 21 # EI
@clockpin  = 22 # CI

def delay(ms); sleep ms * 0.001; end

def setup()
  @io.mode(@datapin, OUTPUT)
  @io.mode(@latchpin, OUTPUT)
  @io.mode(@enablepin, OUTPUT)
  @io.mode(@clockpin, OUTPUT)

  @io.write(@latchpin, LOW)
  @io.write(@enablepin, LOW)
  puts "setup complete"
end

def sb_SendPacket(r=0,g=0,b=0,c=0b00,packet=0)
  packet = (packet << 2)  | (c & 0b11); puts packet.to_s(2).rjust(32, "0") if @debug
  packet = (packet << 10) | (b & 1023); puts packet.to_s(2).rjust(32, "0") if @debug
  packet = (packet << 10) | (r & 1023); puts packet.to_s(2).rjust(32, "0") if @debug
  packet = (packet << 10) | (g & 1023); puts packet.to_s(2).rjust(32, "0") if @debug
  bits = packet.to_s(2).rjust(32, "0").chars.to_a
  bits.insert(22, "_").insert(12, "_").insert(2, "_").insert(1, "_")
  bit_str = bits.join("")
  c_str = c.to_s(2).rjust(2,"0")
  r_str = r.to_s(2).rjust(10,"0")
  g_str = g.to_s(2).rjust(10,"0")
  b_str = b.to_s(2).rjust(10,"0")
  #puts "cmd: #{c_str}\tr: #{r_str},#{g_str},#{b_str}\tpacket: #{bit_str}"

  s1 = 0b11111111_00000000_00000000_00000000
  s2 = 0b00000000_11111111_00000000_00000000
  s3 = 0b00000000_00000000_11111111_00000000
  s4 = 0b00000000_00000000_00000000_11111111
  @io.shiftOut(@datapin, @clockpin, MSBFIRST, (s1 & packet) >> 24)
  @io.shiftOut(@datapin, @clockpin, MSBFIRST, (s2 & packet) >> 16)
  @io.shiftOut(@datapin, @clockpin, MSBFIRST, (s3 & packet) >> 8)
  @io.shiftOut(@datapin, @clockpin, MSBFIRST, (s4 & packet))
  delay(5) # adjustment may be necessary depending on chain length
end

def latch
  @io.write(@latchpin,HIGH) # latch data into registers
  delay(5) # adjustment may be necessary depending on chain length
  @io.write(@latchpin,LOW)
  puts "LATCH" if @debug
end

def main
  setup
  cnt = 0
  dir = 1
  while not @interrupted do
    6.times do |i|
      if cnt == i
        sb_SendPacket(0,0,1023)
      else
        sb_SendPacket(0,0,0)
      end
    end
    latch
    if cnt == 0 then dir =  1 end
    if cnt == 5 then dir = -1 end
    cnt = cnt + dir
    delay 100
  end
end

main
