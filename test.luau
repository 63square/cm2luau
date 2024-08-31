local cm2 = require("lib")

local creation = cm2.new(25 * 100 * 100, 0)

for x = 1, 100 do
    for y = 1, 100 do
        for z = 1, 100 do
            creation:addBlock(cm2.AND, {x, y, z}, {})
        end
    end
end

local blocks, _ = cm2.export(creation)
print(blocks)