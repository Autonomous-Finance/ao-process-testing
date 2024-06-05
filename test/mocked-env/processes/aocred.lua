local json = require "json"

local function newmodule(selfId)
  local aocred = {}

  local ao = require "ao" (selfId)

  aocred.mockBalance = "100"

  function aocred.handle(msg)
    if msg.Tags.Action == "Balance" then
      ao.send({ Target = _G.MainProcessId, Balance = aocred.mockBalance })
    end
  end

  return aocred
end
return newmodule
