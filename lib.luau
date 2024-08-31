-- cm2luau
--
-- MIT License
--
-- Copyright (c) 2024 63square

-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.
--

--!native
--!strict
export type Position = { number }
export type Block = number
export type BlockHandle = number
export type Creation = {
    block_data: buffer,
    connection_data: buffer,

    block_offset: number,
    connection_offset: number,
    block_count: number,

    addBlock: (self: Creation, block: Block, position: Position, properties: { number }) -> BlockHandle,
    connect: (self: Creation, source: BlockHandle, target: BlockHandle) -> nil,
}

--- utility functions
local function itoa(b: buffer, offset: number, value: number): number
    -- todo: make efficient
    local str = tostring(value)
    buffer.writestring(b, offset, str)
    return #str
end

--- creation functions
local creation = {}
function creation.addBlock(self: Creation, block: Block, position: Position, properties: { number }): BlockHandle
    -- block id
    self.block_offset += itoa(self.block_data, self.block_offset, block)

    -- double comma, ignore state
    buffer.writeu16(self.block_data, self.block_offset, 0x2C2C)
    self.block_offset += 2

    -- x value
    self.block_offset += itoa(self.block_data, self.block_offset, position[1])

    -- comma
    buffer.writeu8(self.block_data, self.block_offset, 0x2C)
    self.block_offset += 1
    
    -- y value
    self.block_offset += itoa(self.block_data, self.block_offset, position[2])

    -- comma
    buffer.writeu8(self.block_data, self.block_offset, 0x2C)
    self.block_offset += 1
    
    -- z value
    self.block_offset += itoa(self.block_data, self.block_offset, position[3])

    -- comma
    buffer.writeu8(self.block_data, self.block_offset, 0x2C)
    self.block_offset += 1

    -- properties
    for _, property in ipairs(properties) do
        -- value
        self.block_offset += itoa(self.block_data, self.block_offset, property)

        -- plus
        buffer.writeu8(self.block_data, self.block_offset, 0x2B)
        self.block_offset += 1
    end

    -- end block
    if #properties > 0 then
        -- semicolon, replace last plus
        buffer.writeu8(self.block_data, self.block_offset - 1, 0x3B)
    else
        -- semicolon
        buffer.writeu8(self.block_data, self.block_offset, 0x3B)
        self.block_offset += 1
    end

    -- increment block count and return handle
    self.block_count += 1
    return self.block_count
end

function creation.connect(self: Creation, source: BlockHandle, target: BlockHandle): nil
    -- source
    self.connection_offset += itoa(self.connection_data, self.connection_offset, source)

    -- comma
    buffer.writeu8(self.connection_data, self.connection_offset, 0x2C)
    self.connection_offset += 1

    -- target
    self.connection_offset += itoa(self.connection_data, self.connection_offset, target)

    -- semicolon
    buffer.writeu8(self.connection_data, self.connection_offset, 0x3B)
    self.connection_offset += 1
    return
end

--- cm2luau library
return {
    NOR = 0,
    AND = 1,
    OR = 2,
    XOR = 3,
    BUTTON = 4,
    FLIPFLOP = 5,
    LED = 6,
    SOUND = 7,
    CONDUCTOR = 8,
    CUSTOM = 9,
    NAND = 10,
    XNOR = 11,
    RANDOM = 12,
    TEXT = 13,
    TILE = 14,
    NODE = 15,
    DELAY = 16,
    ANTENNA = 17,
    CONDUCTOR_V2 = 18,
    LED_MIXER = 19,

    --- max_blocks_safe & max_connections_safe refer to the safe limits of blocks and connections.
    --- you can still create blocks above these limits but you will eventually get an error,
    --- this happens around double or triple the safe limit on average. 
    new = function(max_blocks_safe: number, max_connections_safe: number): Creation
        assert(max_blocks_safe > 0, "Max blocks must be greater than 0")
        assert(max_connections_safe >  -1, "Max connections cannot be negative")
        assert(max_blocks_safe < 19884108, "Due to roblox limits you cannot have more than 19,884,107 blocks")
        assert(max_connections_safe < 48806447, "Due to roblox limits you cannot have more than 48,806,446 connections")

        return {
            block_data = buffer.create(54 * max_blocks_safe),
            connection_data = buffer.create(22 * max_connections_safe),

            block_offset = 0,
            connection_offset = 0,
            block_count = 0,

            addBlock = creation.addBlock,
            connect = creation.connect,
        }
    end,

    --- Returns tuple (blocks, connections), can be concatenated for full save
    export = function(creation: Creation): (string, string?)
        -- read blocks
        buffer.writeu8(creation.block_data, creation.block_offset - 1, 0x3F)
        local blocks = buffer.readstring(creation.block_data, 0, creation.block_offset)

        -- read connections
        if creation.connection_offset > 0 then
            buffer.writeu8(creation.connection_data, creation.connection_offset - 1, 0x3F)
            return blocks, buffer.readstring(creation.connection_data, 0, creation.connection_offset + 1)
        else
            return blocks, nil
        end
    end
}