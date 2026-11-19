-- Unit tests for the pure Lua modules. Run: lua5.1 tests/test_lua.lua
package.path = "lua/?.lua;" .. package.path
local protocol = require("coop.protocol")
local marker = require("coop.marker")
local scan = require("coop.scan")
local link = require("coop.link")

local fails, total = 0, 0
local function check(name, cond)
  total = total + 1
  if not cond then fails = fails + 1; io.write("FAIL ", name, "\n") end
end

-- protocol
local st = { seq = 5, game = "IRBO", map = 389, x = 12, y = 30, dir = 2, name = "Ana|x\n" }
local line = protocol.encode(st)
check("encode format", line == "PM1|5|IRBO|389|12|30|2|Anax|END")
local back = protocol.decode(line)
check("decode roundtrip", back and back.map == 389 and back.x == 12 and back.name == "Anax")
check("decode cut line", protocol.decode("PM1|5|IRBO|389|12") == nil)
check("decode bad version", protocol.decode("PM9|5|IRBO|389|12|30|2|A|END") == nil)
check("decode bad number", protocol.decode("PM1|5|IRBO|abc|12|30|2|A|END") == nil)
check("decode nil", protocol.decode(nil) == nil)
check("decode CRLF", protocol.decode(line .. "\r\n") ~= nil)

-- marker
local x, y, on = marker.place({ x = 10, y = 10 }, { x = 10, y = 10 })
check("marker same tile", x == 128 and y == 104 and on)
x, y, on = marker.place({ x = 10, y = 10 }, { x = 12, y = 9 })
check("marker offset", x == 160 and y == 88 and on)
x, y, on = marker.place({ x = 10, y = 10 }, { x = 40, y = 10 })
check("marker clamped", x == 250 and y == 104 and not on)
check("distance", marker.distance({ x = 1, y = 1 }, { x = 4, y = -1 }) == 5)

-- scan with fake RAM: target at 0x10 goes 5 -> 6 -> 5 -> 5
local ram = {}
for a = 0, 0x100, 2 do ram[a] = (a * 7) % 13 end
ram[0x10] = 5
local s = scan.new(function(a) return ram[a] end, 0, 0x100, 2)
check("scan start", s:start() == 129)
ram[0x10] = 6; ram[0x20] = ram[0x20] + 1
check("scan plus1", s:filter(scan.tests.plus1) == 2)
ram[0x10] = 5; ram[0x20] = ram[0x20] + 1
check("scan minus1", s:filter(scan.tests.minus1) == 1 and s:top(1)[1].addr == 0x10)
check("scan wrap", scan.tests.plus1(0xFFFF, 0) and scan.tests.minus1(0, 0xFFFF))

-- link through a temp folder
local tmp = os.tmpname(); os.remove(tmp); os.execute("mkdir -p " .. tmp)
local a = link.new(tmp .. "/", 1, 2)
local b = link.new(tmp .. "/", 2, 1)
check("link no partner", b:read() == nil)
a:write({ seq = 1, game = "IRBO", map = 1, x = 2, y = 3, dir = 0, name = "A" })
local p, age = b:read()
check("link read", p and p.x == 2 and age == 0)
p, age = b:read()
check("link age grows", age == 1)
os.execute("rm -rf " .. tmp)

io.write(string.format("lua: %d/%d ok\n", total - fails, total))
os.exit(fails == 0 and 0 or 1)
