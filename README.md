# AO Process Testing

> **⚠️ ARCHIVED PROJECT**  
> This project is archived and **no longer maintained**. It was initially developed by [Autonomous Finance (AF)](https://autonomous.finance). While the code is provided as-is under the MIT License, users should be aware that there will be no updates, bug fixes, or support provided. Feel free to fork and maintain your own version if needed.

A flexible testing framework for AO process development, supporting unit and integration tests written entirely in Lua. This boilerplate project allows for a powerful testing setup while developing applications on the AO protocol.

## Overview

This testing framework is based on [busted](https://luarocks.org/modules/lunarmodules/busted), enabling you to write your tests **entirely in Lua** without needing to switch between languages.

**Supported test types:**
- Unit tests (including fuzzing)
- Integration tests
- Inter-process communication testing

## Quick Start

### Prerequisites

- Lua 5.1+ installed
- [busted](https://luarocks.org/modules/lunarmodules/busted) testing framework
- Basic understanding of AO process development

### Installation

1. Clone this repository
2. Install dependencies (busted via luarocks)
3. Run tests: `npm test` or `bash ./scripts/test.sh`

## Usage Examples

The files `process.lua` and `rewards.lua` contain example code you would typically have in your AO process (handlers and global state).

The files `process_test.lua` and `rewards_test.lua` contain examples of integration tests and unit tests, respectively.

### Integration Test Example

```lua
-- application code (process.lua)

Handlers.add(
  "greet",
  Handlers.utils.hasMatchingTag("Action", "Greet"),
  function(msg)
    Greetings = Greetings + 1
    LastGreeting = msg.Data
  end
)

-- integration test code (process_test.lua)

it("should increment Greetings count on a Greet message", function()
  ao.send({ Target = ao.id, Action = "Greet", Data = "Hello" })
  assert.are.equal(_G.Greetings, 1)
end)
```

### Unit Test Example

```lua
-- application code (rewards.lua)

mod.nextReward = function(msg)
  local maximumEntry = mod.getMaximumEntry()
  if maximumEntry and maximumEntry.value >= mod.Threshold then
    return maximumEntry.value * mod.RewardFactor
  else
    return 0
  end
end

-- unit test code (rewards_test.lua)

it("it should return 0 reward if we are below threshold", function()
    rewards.Threshold = 42
    rewards.RewardFactor = 10
    -- mock this for the purpose of the test
    local originalGetMaximum = rewards.getMaximumEntry

    rewards.getMaximumEntry = function()
      return { value = 41 }
    end

    assert.are.equal(rewards.nextReward(), 0)
    rewards.getMaximumEntry = originalGetMaximum
  end)
```

## Getting Started

### Starting From Scratch

If you start from scratch with a new project:
- Use `process.lua` as the place to define and add your Handlers
- Use files like `rewards.lua` for creating lib-like modules that implement helpers, handler execution or handler matching logic

### Adding to an Existing Project

1. Add the `scripts/` and `test/` directories from this repository to your project
2. Replace `process.lua` with your main process file. If you prefer another name, sync the name in `test/process_test.lua`
3. Include your lib-like modules. They can be simply required into the `_test.lua` files: `local rewards = require "rewards"`

### Project Assumptions

This testing setup assumes that:
- Your repo has a single "main" process
- The main process handlers are added in the file `process.lua`
- `process.lua` potentially requires lua modules (lib-like) in order to define the handlers

## Testing Philosophy

The main goal is to test as thoroughly as needed without compromising good design patterns in the actual application code.

### Design Recommendations

> In order to **easily create unit tests**, it's better to have the top level lua file only define handlers, while execution functions are in one or multiple dedicated modules.
> 
> Additionally, we suggest splitting out any `ao.send({})` that occurs as part of the handler execution into its own function within the dedicated module that is to be unit tested. That function can be mocked when doing unit tests, so that they do something other than `ao.send({})` (ideally, something verifiable with assertions)

This principle makes it possible to **"unit-test"** the execution of specific handlers **without the need for mocking the message** that triggers that specific handler.

### Types of Testing

By building in the AO paradigm, we've identified the following conceptual differentiation between **types of testing**:

1. **Integration tests between processes** - requires mocking other processes and part of ao itself
2. **Integration between modules (libs)** that serve a single process - these can also be viewed as unit tests on the single process itself
3. **Unit tests for modules (libs)** that serve a single process

## Unit Tests (Type 2 and 3)

If a unit (module) internally uses functions or variables which are also exposed, this setup allows for ad-hoc changes to these functions and values as needed for different tests. See `rewards_test.lua` for an example on how to leverage this in order to perform **fuzzing**.

Additional unit test files can be added. They should be named similarly, as specified in `test/setup.lua`.

## Integration Tests (Type 1)

The approach is to test one main *app process* (`process.lua`) with its actual Handlers and imported modules, without modifying its original code in any way.

**Other processes** that our *app process* interacts with **are mocked** in `test/mocked-env/processes`.

### Inter-Process Communication

Inter-process communication occurs via the familiar `ao.send({...})` call. In addition to the familiar key-value pairs of its argument, `ao.send` also supports:
- `From = "xyz...321"` - allows you to impersonate accounts when sending messages. This enables testing of access control.
- `Timestamp = 1234` - allows you to simulate specific timing of messages. This enables testing of cooldown logic.

### Mocked `ao` Environment

`ao` **is mocked** such that:
- Messages targeting our *app process* are handled according to its actual handlers (to be tested)
- Messages targeting mock processes are handled via their `handle(msg)` function which they expose for the purpose of being used in integration tests
- Messages targeting users can be handled by storing them in a global value `_G.LastMessageToOwner`, or something more sophisticated like `_G.MessagesToWallets` if test assertions require more info than just the last received message
- The process environment `ao.env.Process` can be set as needed in the test file (see `process_test.lua`). This is especially useful if custom tags are passed into the tested process when it is spawned.

### Flexibility

You are free to implement the internal state of mocked processes as you see fit, such that subsequent calls to `handle(msg)` yield realistic results.

You can skip execution of `ao.send()` entirely for any particular test file by using `_G.IsInUnitTest = true`. This is useful if you want to perform a unit test of **Type 2**: A specific handler is implemented as a separate function as described above. It performs internal state updates of many kinds, involving multiple modules. During execution it sends out messages that are not essential to the correct execution flow (logging, syncing, success confirmations, etc.). By using the unit test flag, it's possible to test these handler execution functions without executing the message sends.

### Virtual Time

You can use `_G.VirtualTime` in order to test logic related to time (time locks, cooldown periods, etc.). The messages sent via `ao.send()` will use the `_G.VirtualTime` value if it is not `nil`. However, using an explicit `Timestamp = 1234` in the message payload overrides any virtual time value.

### Global Values & Mock Processes

**Key global variables:**
- `_G.MainProcessId` - an arbitrary ID assigned to the *app process* such that `ao` and the mocked processes can reference it

**Setting up mocked process references:**

```lua
_G.AoCredProcessId = 'AoCred-123xyz'

_G.Processes = {
  [_G.AoCredProcessId] = require 'aocred' (_G.AoCredProcessId)
}
```

### Controlled Logging

With all testing logic being in lua, it's possible to leverage the native `print` function. We wrap it in a higher order function such as to allow for specifying a verbosity level for each logging. See the function `_G.printVerb` at the top of the example `test/*_test.lua` files.

For example, any logging related to message passing and handling is done with level 2 verbosity, see `printVerb(2)('> LOG: ' .. 'SKIPPING DEFAULT HANDLER')` in `test/mocked-env/ao/handlers.lua`.

By using this approach you can also change the verbosity of your test suite while it is executing, such as to have **only specific tests or parts of one test** run with high verbosity, while others keep a low or 0 verbosity. That way you can more effectively focus on failing tests or parts of tests when debugging.

Also, by making `_G.printVerb` a global function you can for a brief time include this logging in your application code, just for the time of debugging while some of your tests are failing.

## Implementation Details

### Replicated Code - Mocking `ao` & `aos`

`test/mocked-env/ao/ao.lua` contains minimum functionality such as to facilitate the simulation of message communication. It borrows from the setup of the [aos-test-kit](https://github.com/permaweb/aos-test-kit).

We replicate some code from [aos](https://github.com/permaweb/aos.git) - `test/mocked-env/ao/handlers.lua` and `test/mocked-env/ao/handlers-utils.lua` are used for matching the actual handlers of *app process*.

In order to keep things simple, the default handlers associated with each process (`_default` and `_eval`) are not added to *app process* and so they never kick in as they would in production. For the purpose of testing, we find them not essential.

### Alternative Testing Approaches

Testing can also be performed with the ao-loader from https://github.com/permaweb/ao, see the [npm package](https://www.npmjs.com/package/@permaweb/ao-loader?activeTab=readme) and how it is used in the [**aos-test-kit**](https://github.com/permaweb/aos-test-kit).

While the aos-test-kit does facilitate TDD while developing an AO process, it offers less flexibility or capabilities in terms of:
- Systematically setting up the global state of the process to be tested (*app process*)
- Assertions on the global state of the process to be tested (should not need to go through Evals for this purpose)
- Allowing inter-process interaction with mocked processes

Additionally, the present setup makes it possible to write the tests entirely in Lua, which may be preferable in some cases.

## Security Considerations

This is a testing framework designed for local development and testing. When using this framework:

- **Never commit sensitive data** - The framework uses mock IDs and test values. Ensure no production credentials or keys are included in test files
- **Protected keys** - The mocked `ao.send()` implementation protects certain keys (`Id`, `Owner`, `Module`, `Block-Height`) from being overwritten to prevent security issues
- **Test isolation** - Each test should reset global state appropriately to avoid test interference

## Contributing

> **Note:** This project is archived and no longer maintained. However, if you fork this project, contributions would be welcome in your fork.

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.

## Acknowledgments

- Initially developed by [Autonomous Finance (AF)](https://autonomous.finance)
- Built on [busted](https://luarocks.org/modules/lunarmodules/busted) testing framework
- Inspired by [aos-test-kit](https://github.com/permaweb/aos-test-kit) and [aos](https://github.com/permaweb/aos.git)
