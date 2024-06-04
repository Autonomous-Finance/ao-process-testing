local mod = {}

Entries = Entries or {}

mod.Threshold = 100
mod.RewardFactor = 10

mod.getMaximumEntry = function()
  -- TODO iterate over Entries, get maximum one
  return nil
end

--[[
  if max entry is above Threshold, reward is given out
]]
mod.nextReward = function(msg)
  local maximumEntry = mod.getMaximumEntry()
  if maximumEntry and maximumEntry.value >= mod.Threshold then
    return maximumEntry.value * mod.RewardFactor
  else
    return 0
  end
end

return mod
