Greetings = Greetings or 0
LastGreeting = LastGreeting or nil
LastBalance = nil

Handlers.add(
  "greet",
  Handlers.utils.hasMatchingTag("Action", "Greet"),
  function(msg)
    Greetings = Greetings + 1
    LastGreeting = msg.Data
  end
)

Handlers.add(
  "receiveBalance",
  function(msg)
    return msg.Tags.Balance ~= nil and msg.From == "AoCred"
  end,
  function(msg)
    if msg.Tags.Action == "Balance" then
      LastBalance = msg.Data
    end
  end
)
