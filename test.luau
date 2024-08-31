local cm2 = require("lib")

local creation = cm2.new(25 * 100 * 100, 0)

local start = os.clock()

for x = 1, 100 do
    for y = 1, 100 do
        for z = 1, 100 do
            creation:addBlock(cm2.AND, {x, y, z}, nil)
        end
    end
end

local generate = os.clock()

local blocks, _ = cm2.export(creation)

local export = os.clock()

print(`Generation: {generate - start} | Export: {export - generate}\n\n`)
print(blocks)