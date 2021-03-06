
local setmetatable = setmetatable
local tostring     = tostring
local print        = print
local getmetatable = getmetatable

module "klass"

local Klass = {}
setmetatable(Klass, Klass)
Klass.__index    = Klass
Klass.__tostring = function(self) return self.name end
Klass.name       = "Klass"

function Klass:new(klass)
  print("Klass' new called")
  klass = setmetatable(klass or {}, Klass)
  klass.__index    = klass
  klass.__tostring = Klass.__tostring

  function klass:new(object)
    print("Cat's new called")
    object = setmetatable(object or {}, klass)
    return object
  end

  function klass:klass()
    return getmetatable(self)
  end

  return klass
end

local Cat = Klass:new{name = "Cat"}
print(Cat:klass())

function Cat:tostring()
  return self.name
end

function Cat:meow()
  print(tostring(self:klass()) .. ": " .. tostring(self) .. ": Meow~")
end

local carol = Cat:new{name="Carol"}
local marol = Cat:new{name="Marol"}

carol:meow()
marol:meow()
carol:meow()

-- Carol: Meow~
-- Marol: Meow~
-- Carol: Meow~

return Klass
