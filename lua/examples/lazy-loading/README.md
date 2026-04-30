# Lazy Loading Example

This example shows how to keep startup files small by registering lightweight proxy callbacks, then loading the larger tool or widget implementation only when Ethos actually uses it.

Lazy loading is useful on radios because Lua memory and per-cycle CPU time are limited. If a script registers several tools, widgets, or optional features at startup, loading every implementation immediately can spend memory on code that the pilot may never open during that model session.

Use lazy loading when:

- A module is optional, such as a widget, setup tool, diagnostics page, or rarely used menu.
- Startup memory matters more than the tiny delay of loading the module the first time it is used.
- The registered item only needs static metadata at startup, such as `name`, `key`, or `icon`.

Avoid lazy loading when:

- The module is required immediately for a background task or safety-critical behavior.
- The module's top-level code must run during script initialization.
- The first-use delay would happen in a hot path such as a frequent `wakeup` loop.

The reusable helper is `lazy.lua`. Copy that file next to your script, then wrap the callbacks in the registration table you pass to `system.registerSystemTool()` or `system.registerWidget()`.

Files in this example:

- `main.lua` loads the two tiny registration demos.
- `lazy.lua` contains the reusable lazy-loading helper.
- `tool.lua` demonstrates lazy `registerSystemTool()` registration.
- `widget.lua` demonstrates lazy `registerWidget()` registration.
- `tool_impl.lua` and `widget_impl.lua` contain the heavier callback code that is loaded on first use.

The pattern is:

1. Keep only static metadata and registration code in the startup file.
2. Put the real callback functions in an implementation module.
3. Use `lazy.wrap()` to export proxy callbacks for the methods you want to defer.
4. Cache the returned module table so later callbacks reuse it.
5. Remember load failures so Ethos does not retry and print errors every tick.

`tool_impl.lua` is loaded only when the "Lua Lazy Tool" system tool is opened. `widget_impl.lua` is loaded only when the "Lua Lazy Widget" is created, painted, configured, or otherwise called by Ethos.

Minimal system tool registration:

```lua
local lazy = assert(loadfile("lazy.lua"))()

local tool = lazy.wrap({
  name = "My Tool",
}, "tool_impl.lua", {"create", "wakeup", "event", "close"})

system.registerSystemTool(tool)
```

Minimal widget registration:

```lua
local lazy = assert(loadfile("lazy.lua"))()

local widget = lazy.wrap({
  key = "my-widget",
  name = "My Widget",
}, "widget_impl.lua", {"create", "paint", "wakeup", "configure", "read", "write", "close"}, {
  create = function() return {} end,
})

system.registerWidget(widget)
```

This mirrors the approach used by larger scripts: register cheap metadata up front, defer optional code and assets until they are needed, and keep wakeup paths from doing unnecessary allocation.
