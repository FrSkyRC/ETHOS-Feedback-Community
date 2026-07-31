# Lazy Loading Example

This example shows how to keep startup files small by registering lightweight proxy callbacks, then loading the larger tool or widget implementation only when Ethos actually calls it.

Lazy loading is useful on radios because Lua memory and per-cycle CPU time are limited. If a script registers several tools, widgets, or optional features at startup, loading every implementation immediately can spend memory on code that the pilot may never open during that model session.

**Read "Known limitations" below before using this for a widget's or system tool's top-level registration.** The tradeoff is real but it is not free, and it has gone wrong in practice for at least one production Ethos Lua suite.

Use lazy loading when:

- A module is optional, such as a widget, setup tool, diagnostics page, or rarely used menu.
- Startup memory matters more than the tiny delay of loading the module the first time it is used.
- The registered item only needs static metadata at startup, such as `name`, `key`, or `icon`.

Avoid lazy loading when:

- The module is required immediately for a background task or safety-critical behavior.
- The module's top-level code must run during script initialization.
- The first-use delay would happen in a hot path such as a frequent `wakeup` loop.
- The widget/tool persists its own settings via `read`/`write` — see "Known limitations" below; wrapping these usually loads the module almost immediately anyway.

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
4. `lazy.wrap()` caches the loaded module and, the moment it loads (or fails to load), replaces every wrapped method with its final direct implementation — see "How the proxy resolves itself" below.
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

This mirrors the approach used by larger scripts: register cheap metadata up front, defer optional code and assets until they are needed, and keep wakeup paths from doing unnecessary allocation once the module has loaded.

## How the proxy resolves itself

A naive lazy proxy stays a proxy forever: every call, for the widget's or tool's entire remaining lifetime, pays an extra closure call plus a table lookup into the loaded module, even long after that module is cached. For a hot path like `paint()`/`wakeup()` — called on every frame or tick for as long as the widget is visible — that is a small but permanent, avoidable cost.

`lazy.wrap()` avoids this: the *first* call to any wrapped method loads the module (or records that it failed) and then overwrites every wrapped method on the registration table with its final, direct implementation (the module's function, or the fallback if one was provided and the module didn't supply that method). Every call after that first one goes straight to the real function — no proxy, no lookup. The only ongoing cost is the one-time cost you'd pay on first use regardless of how you loaded the module.

This relies on Ethos looking up `widget.wakeup`/`tool.wakeup` etc. fresh from the registration table on each call, rather than capturing a fixed reference to the function at `registerWidget()`/`registerSystemTool()` time. That matches observed behavior (widgets are commonly built by mutating fields on the same table after registration), but if you're targeting a specific firmware version and see stale proxy behavior, verify this on your own hardware before relying on it.

## Known limitations

**Deferring a widget's or tool's *top-level* registration this way has caused problems in practice.** At least one production Ethos Lua suite tried exactly this pattern — lightweight proxy callbacks up front, real implementation loaded on first use — for its top-level `registerWidget()`/`registerSystemTool()`/`registerTask()` registrations, and reverted it after on-device testing showed it *increased* retained RAM over a session compared to just registering the real callbacks directly at startup. The suite's own migration note: *"registers direct callbacks eagerly. This costs more startup RAM than lazy proxies, but avoids retained-RAM growth observed on device with the lazy callback layer."*

The exact mechanism wasn't conclusively isolated, but it's consistent with Ethos's own `form`/widget system retaining some allocations outside Lua's normal GC reachability graph — a platform trait a userspace proxy layer can't work around. If you adopt this pattern for a widget or system tool the pilot uses every session (not an occasionally-opened diagnostics/setup tool), measure retained RAM on your actual target hardware across a realistic session before and after, rather than assuming lazy loading is a strict win. `system.getMemoryUsage()` (where available) or repeated `collectgarbage("count")` samples across a navigation loop are enough to catch this kind of regression.

**Wrapping `read`/`write`/`configure` alongside `paint`/`wakeup` often doesn't defer loading as much as it looks like it should.** Ethos typically calls a widget's `read()` as soon as it's placed on a screen, to restore persisted settings — independent of whether the pilot ever actually views or interacts with it. If your widget persists any setting (most do), wrapping `read` in the same lazy group as `paint`/`wakeup` means the "heavy" implementation module usually loads almost immediately anyway, at screen-load time, not at first paint. You still get the self-resolving-proxy benefit (see above) once that happens, but not the startup-RAM deferral the pattern advertises. If startup RAM is the actual goal, consider keeping `create`/`read`/`write`/`configure` eager and reserving lazy wrapping for callbacks that genuinely don't fire until the pilot interacts with the widget.
