---@diagnostic disable: duplicate-set-field
require("test.setup")()

_G.IsInUnitTest = true -- set this per test file to keep ao.send() from doing anything
_G.VerboseTests = 0    -- how much logging to see (0 - none at all, 1 - important ones, 2 - everything)
-- optional logging function that allows for different verbosity levels
_G.printVerb = function(level)
  level = level or 2
  return function(...) -- define here as global so we can use it in application code too
    if _G.VerboseTests >= level then print(table.unpack({ ... })) end
  end
end

local rewards = require "rewards"

describe("rewards", function()
  local originalGetMaximumEntry
  local originalThreshold
  local originalRewardFactor

  setup(function()
    originalGetMaximumEntry = rewards.getMaximumEntry
    originalThreshold = rewards.Threshold
    originalRewardFactor = rewards.RewardFactor
  end)

  teardown(function()
    rewards.getMaximumEntry = originalGetMaximumEntry
    rewards.Threshold = originalThreshold
    rewards.RewardFactor = originalRewardFactor
  end)


  it("it should return 0 reward if we are below threshold", function()
    rewards.Threshold = 42
    rewards.RewardFactor = 10
    local originalGetMaximum = rewards.getMaximumEntry
    rewards.getMaximumEntry = function()
      return { value = 41 }
    end

    assert.are.equal(rewards.nextReward(), 0)

    rewards.getMaximumEntry = originalGetMaximum
  end)

  -- FUZZER
  it("it should return with correct calculation if we are above or at threshold", function()
    for i = 0, 100 do
      rewards.Threshold = math.random(1, 10000)
      local maxEntryVal = math.random(rewards.Threshold, rewards.Threshold * 2)
      rewards.RewardFactor = math.random(1, 100)
      local originalGetMaximum = rewards.getMaximumEntry
      rewards.getMaximumEntry = function()
        return { value = maxEntryVal }
      end

      assert.are.equal(rewards.nextReward(), maxEntryVal * rewards.RewardFactor)

      rewards.getMaximumEntry = originalGetMaximum
    end
  end)
end)
