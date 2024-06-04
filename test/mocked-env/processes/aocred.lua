local function newmodule(selfId)
  local aocred = {}

  local ao = require "ao" (selfId)

  function aocred.handle(msg)
    if msg.Tags.Action == "Balance" then
      ao.send({ Target = _G.MainProcessId, Balance = "100" })
    end
  end

  return aocred
end
return newmodule
