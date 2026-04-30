# Lazy Loading Example

This example shows how to keep `main.lua` small by registering lightweight proxy callbacks, then loading the larger tool or widget implementation only when Ethos actually uses it.

Lazy loading is useful on radios because Lua memory and per-cycle CPU time are limited. If a script registers several tools, widgets, or optional features at startup, loading every implementation immediately can spend memory on code that the pilot may never open during that model session.

Use lazy loading when:

- A module is optional, such as a widget, setup tool, diagnostics page, or rarely used menu.
- Startup memory matters more than the tiny delay of loading the module the first time it is used.
- The registered item only needs static metadata at startup, such as `name`, `key`, or `icon`.

Avoid lazy loading when:

- The module is required immediately for a background task or safety-critical behavior.
- The module's top-level code must run during script initialization.
- The first-use delay would happen in a hot path such as a frequent `wakeup` loop.

The pattern in `main.lua` is:

1. Keep only small proxy functions in the startup file.
2. Call `loadfile()` inside the proxy the first time a callback is invoked.
3. Cache the returned module table so later callbacks reuse it.
4. Remember load failures so Ethos does not retry and print errors every tick.

`tool.lua` is loaded only when the "Lua Lazy Tool" system tool is opened. `widget.lua` is loaded only when the "Lua Lazy Widget" is created, painted, configured, or otherwise called by Ethos.

This mirrors the approach used by larger scripts: register cheap metadata up front, defer optional code and assets until they are needed, and keep wakeup paths from doing unnecessary allocation.
