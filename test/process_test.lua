---@diagnostic disable: duplicate-set-field
require("test.setup")()

_G.MainProcessId = '123xyzMySelfabc321'
_G.AoCredProcessId = 'AoCred-123xyz'

_G.Processes = {
  [_G.AoCredProcessId] = require 'aocred' (_G.AoCredProcessId)
}

_G.Handlers = require "handlers"

local ao = require "ao" (_G.MainProcessId)
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
    assert.are.equals(_G.Greetings, 1)
  end)

  it("should update LastGreeting on a Greet message", function()
    local testGreeting = "HelloThere"
    ao.send({ Target = ao.id, Action = "Greet", Data = testGreeting })
    assert.are.equals(_G.LastGreeting, testGreeting)
  end)

  it("should have no last balance at first", function()
    assert.is_nil(_G.LastBalance)
  end)

  it("should obtain last balance from aocred", function()
    ao.send({ Target = _G.AoCredProcessId, Action = "Balance" })
  end)
end)
