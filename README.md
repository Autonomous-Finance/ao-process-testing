# AO Process Testing

This is a boilerplate project to allow for a flexible and powerful testing setup while developing applications on AO.

It is based on [busted](https://luarocks.org/modules/lunarmodules/busted), so you can write your tests **entirely in Lua**.

This boilerplate is suitable for
- unit tests (including fuzzing) 
- integration tests

> ⚠️ The project is under development and may have bugs or design shortcomings. Feel free to contribute by opening issues or PR-ing. We welcome any effort aimed at making this a better tool for the community.

## Unit Tests

If a unit (module) internally uses functions or variables which are also exposed, this setup allows for ad-hoc changes to these functions and values as needed for different tests. See `rewards_test.lua` for an example on how to leverage this in order to perform **fuzzing**.

Additional unit test files can be added. They should be named similarly, as specified in `test/setup.lua`.

## Integration Tests

The approach is to test one main *app process* (`process.lua`) with its actual Handlers and imported modules, without modifying its original code in any way.

**Other processes** that our *app process* interacts with **are mocked** in `test/mocked-env/processes`.

Inter-process communication occurs via the familiar `ao.send({...})` call.
In addition to the familiar key-value pairs of its argument, `ao.send` also supports 
- a `From = "xyz...321"` which allows you to impersonate accounts when sending messages. This enables for instance the testing of access control.
- a `Timestamp = 1234` which allows you to simulate specific timing of the messages. This enables for instance the testing of cooldown logic.

`ao` **is mocked** such that
- messages targeting our *app process* are handled according to its actual handlers (to be tested)
- messages targeting mock processes are handled via their `handle(msg)` function which they expose for the purpose of being used in integration tests.

### Flexibility 

You are free to implement the internal state of mocked processess as you see fit, such that subsequent calls to `handle(msg)` yield realistic results.

### Global values & Mock Processes

`_G.MainProcessId` - an arbitrary ID assigned to the *app process* such that `ao` and the mocked processes can reference it.

And this is how we set up mocked process references

```lua
_G.AoCredProcessId = 'AoCred-123xyz'

_G.Processes = {
  [_G.AoCredProcessId] = require 'aocred' (_G.AoCredProcessId)
}
```

### Controlled Logging

With all testing logic being in lua, it's possible to leverage the native `print` function. All logging related to the mock message passing and handling can be toggled by changing the `_G.VerboseTests`, which is set specifically for every `_test.lua` file.

### Replicated Code - Mocking `ao` & `aos`

`test/mocked-env/ao/ao.lua` contains minimum functionality such as to facilitate the simulation of message communication. It borrows from the setup of the [aos-test-kit](https://github.com/permaweb/aos-test-kit).

We replicate some code from [aos](https://github.com/permaweb/aos.git) - `test/mocked-env/ao/handlers.lua` and `test/mocked-env/ao/handlers-utils.lua` are used for matching the actual handlers of *app process*

In order to keep things simple, the default handlers associated with each process (`_default` and `_eval`) are not added to *app process* and so they never kick in as they would in production.
For the purpose of testing, we find them not essential.

### An alternative to `@permaweb/ao-loader` & aos-test-kit

Testing can also be performed with the ao-loader from https://github.com/permaweb/ao, see the [npm package](https://www.npmjs.com/package/@permaweb/ao-loader?activeTab=readme) and how it is used in the [**aos-test-kit**](https://github.com/permaweb/aos-test-kit).

While the aos-test-kit does facilitate TDD while developing an AO process, it offers less flexibility or capabilities in terms of 
- systematically setting up the global state of the process to be tested (*app process*), as well as 
- assertions on the global state of the process to be tested (should not need to go through Evals for this purpose)
- allowing inter-process interaction with mocked processes

Additionally, the present setup makes it possible to write the tests entirely in Lua, which may be preferrable in some cases.


## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.
