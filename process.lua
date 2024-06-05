Greetings = Greetings or 0
LastGreeting = LastGreeting or nil
LastBalance = nil
PublicName = 'Process42'

Handlers.add(
  "setPublicName",
  Handlers.utils.hasMatchingTag("Action", "SetPublicName"),
  function(msg)
    if msg.From ~= Owner then
      return
    end
    PublicName = msg.Tags.Name
  end
)

Handlers.add(
  "greet",
  Handlers.utils.hasMatchingTag("Action", "Greet"),
  function(msg)
    Greetings = Greetings + 1
    LastGreeting = msg.Data
  end
)

Handlers.add(
  "requestBalance",
  Handlers.utils.hasMatchingTag("Action", "RequestBalance"),
  function(msg)
    ao.send({ Target = _G.AoCredProcessId, Action = "Balance" })
  end
)

Handlers.add(
  "receiveBalance",
  function(msg)
    return msg.Tags.Balance ~= nil and msg.From == _G.AoCredProcessId
  end,
  function(msg)
    LastBalance = msg.Tags.Balance
  end
)
