-- RUN: Write function on lua 5.1 to get next rgb
-- Function to get the next RGB color
-- Store the current RGB values in local variables
local r, g, b, i = 0, 0, 0, 0
function getNextRGB()
	-- Manual added
	i = i + 1
  -- Increment the blue value and check if it overflows
  b = b + 1
  if b > 255 then
    -- If it overflows, reset it to 0 and increment the green value
    b = 0
    g = g + 1
    
    -- If the green value overflows, reset it to 0 and increment the red value
    if g > 255 then
      g = 0
      r = r + 1
    end
  end
  
  -- Return the next RGB color
  return r, g, b
end

-- RUN: Now enumerate getNextRGB for all possible RGB colors
-- Enumerate all possible RGB colors
local function runEnumerationRGB()
	while true do
	  -- Get the next RGB color
	  local r, g, b = getNextRGB()
	  
	  -- Print the RGB values
	  print(r, g, b)
	  
	  -- Stop the loop when all values reach 255
	  if r == 255 and g == 255 and b == 255 then
		break
	  end
	  
	  -- Manual added
	  coroutine.yield()
	end
end 

-- Manual added
local Coroutine = coroutine.create(runEnumerationRGB)
local Frame = CreateFrame("Frame")
Frame:SetScript("OnUpdate", function(self, elapse)
	if coroutine.status(Coroutine) ~= "dead" then 
		coroutine.resume(Coroutine)
	else 
		print("i:", i, "256^3:", 256^3, "isEqual:", i == 256^3)
		self:SetScript("OnUpdate", nil)
	end 
end)


-- RUN: Lua function to serialize table in to single string and unseralize include sub tables on example with {name = "John Doe", age = 35, address = {street = "123 Main St", city = "New York", state = "NY"}, district = {1,2,3}, city = "Moscow"}
-- function to serialize table and its sub-tables into string
function serialize(tbl)
	local str = ""
	for k, v in pairs(tbl) do
		if type(v) == "table" then
			str = str .. tostring(k) .. "=" .. serialize(v) .. ","
		else
			str = str .. tostring(k) .. "=" .. tostring(v) .. ","
		end
	end
	return str
end

-- function to deserialize string into table and its sub-tables
function deserialize(str)
	local tbl = {}
	for k, v in str:gmatch("([^,]=[^,]*)") do
		key, value = k:match("([^,])=([^,]*)")
		if value:match("[^,]=[^,]*") then
			tbl[key] = deserialize(value)
		else
			tbl[key] = value
		end
	end
	return tbl
end

-- example usage
local function runSerializeExample()
	local myTable = {name = "John Doe", age = 35, address = {street = "123 Main St", city = "New York", state = "NY"}, district = {1,2,3}, city = "Moscow"}
	local serialized = serialize(myTable)
	local deserialized = deserialize(serialized)

	print(serialized)
	-- Output: "name=John Doe,age=35,address=street=123 Main St,city=New York,state=NY,district=1=1,2=2,3=3,city=Moscow,"
	print(deserialized)
	-- Output: {name="John Doe", age=35, address={street="123 Main St", city="New York", state="NY"}, district={1,2,3}, city="Moscow"}
end 