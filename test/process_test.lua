---@diagnostic disable: duplicate-set-field
require("test.setup")()

_G.VerboseTests = 0                    -- how much logging to see (0 - none at all, 1 - important ones, 2 - everything)
_G.VirtualTime = _G.VirtualTime or nil -- use for time travel
-- optional logging function that allows for different verbosity levels
_G.printVerb = function(level)
  level = level or 2
  return function(...) -- define here as global so we can use it in application code too
    if _G.VerboseTests >= level then print(table.unpack({ ... })) end
  end
end

_G.Owner = '123MyOwner321'
_G.MainProcessId = '123xyzMySelfabc321'
_G.AoCredProcessId = 'AoCred-123xyz'

_G.Processes = {
  [_G.AoCredProcessId] = require 'aocred' (_G.AoCredProcessId)
}

_G.Handlers = require "handlers"

_G.ao = require "ao" (_G.MainProcessId) -- make global so that the main process and its non-mocked modules can use it
-- => every ao.send({}) in this test file effectively appears as if the message comes the main process

_G.ao.env = {
  Process = {
    Tags = {
      ["Name"] = "GreeterProcess",
      -- ... add other tags that would be passed in when the process is spawned
    }
  }
}

local process = require "process" -- require so that process handlers are loaded
-- local utils = require "utils"
-- local bint = require ".bint" (512)


local resetGlobals = function()
  -- according to initialization in process.lua
  _G.Greetings = 0
  _G.LastGreeting = nil
  _G.LastBalance = nil
end


describe("greetings", function()
  setup(function()
    -- to execute before this describe
  end)

  teardown(function()
    -- to execute after this describe
  end)

  it("should have no LastGreeting", function()
    assert.is_nil(_G.LastGreeting)
  end)

  it("should have a 0 Greetings count", function()
    assert.are.equal(_G.Greetings, 0)
  end)

  it("should increment Greetings count on a Greet message", function()
    ao.send({ Target = ao.id, Action = "Greet", Data = "Hello" })
    assert.are.equal(_G.Greetings, 1)
  end)

  it("should update LastGreeting on a Greet message", function()
    local testGreeting = "HelloThere"
    ao.send({ Target = ao.id, Action = "Greet", Data = testGreeting })
    assert.are.equal(_G.LastGreeting, testGreeting)
  end)

  it("should have no last balance at first", function()
    assert.is_nil(_G.LastBalance)
  end)

  it("should request and obtain last balance from aocred", function()
    ao.send({ Target = _G.MainProcessId, Action = "RequestBalance" })
    local mockBalance = _G.Processes[_G.AoCredProcessId].mockBalance
    assert.are.equal(_G.LastBalance, mockBalance)
  end)

  it("should allow the owner to change the process name", function()
    local newName = "NewName1"
    ao.send({ Target = _G.MainProcessId, Action = "SetPublicName", Name = newName, From = _G.Owner })
    assert.are.equal(_G.PublicName, newName)
  end)

  it("should prevent non-owners from changing the process name", function()
    local newName = "NewName2"
    ao.send({ Target = _G.MainProcessId, Action = "SetPublicName", Name = newName, From = 'ANON' })
    assert.are_not.equal(_G.PublicName, newName)
  end)
end)
