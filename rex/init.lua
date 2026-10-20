-- Port of ~/.config/herdr/config.toml, which mirrors ~/.tmux.conf.
-- Herdr "workspace" = Rex session, "tab" = window, "pane" = block.

local prefix = "ctrl+a"
local function p(key) return prefix .. ">" .. key end

-- set-option -g prefix C-a; press it twice to send C-a to the terminal.
rex.bind(p(prefix), "pane.send_key", { key = prefix })

-- bind | split-window -h (side by side), bind - split-window -v (stacked)
rex.bind(p("shift+\\"), "pane.split", { direction = "right" })
rex.bind(p("-"), "pane.split", { direction = "down" })

-- bind -n C-h/C-j/C-k/C-l select-pane
rex.bind("ctrl+h", "pane.focus", { direction = "left" })
rex.bind("ctrl+j", "pane.focus", { direction = "down" })
rex.bind("ctrl+k", "pane.focus", { direction = "up" })
rex.bind("ctrl+l", "pane.focus", { direction = "right" })

-- bind -n C-\ select-pane -l. Rex keeps no focus history, so this is the
-- previous pane in layout order (identical with two panes).
rex.bind("ctrl+\\", "pane.focus_previous")

-- bind -r h/j/k/l resize-pane. Amount is a percentage of the split
-- (herdr's 0.03 ratio).
local resize_step = 3
local dirs = { h = "left", j = "down", k = "up", l = "right" }
for key, dir in pairs(dirs) do
  rex.bind(p(key), "pane.resize", { direction = dir, amount = resize_step })
end

-- prefix+r: resize mode, hjkl or arrows, Enter or Escape to leave.
rex.mode("resize", { exclusive = true })
rex.bind(p("r"), "client.mode.enter", { name = "resize" })
for key, dir in pairs(dirs) do
  rex.bind("resize/" .. key, "pane.resize", { direction = dir, amount = resize_step })
  rex.bind("resize/" .. dir, "pane.resize", { direction = dir, amount = resize_step })
end
rex.bind("resize/enter", "client.mode.exit")

-- prefix+g: navigate mode. hjkl/arrows move between panes, shift+k/shift+j
-- move up/down the session list. Enter or Escape to leave.
rex.mode("navigate", { exclusive = true })
rex.bind(p("g"), "client.mode.enter", { name = "navigate" })
for key, dir in pairs(dirs) do
  rex.bind("navigate/" .. key, "pane.focus", { direction = dir })
  rex.bind("navigate/" .. dir, "pane.focus", { direction = dir })
end
rex.bind("navigate/shift+k", "session.previous")
rex.bind("navigate/shift+j", "session.next")
rex.bind("navigate/enter", "client.mode.exit")

-- bind ( switch-client -p / bind ) switch-client -n
rex.bind(p("shift+9"), "session.previous")
rex.bind(p("shift+0"), "session.next")

-- bind & kill-window
rex.bind(p("shift+7"), "client.tab.close")

-- herdr's default prefix bindings that the herdr config didn't override.
-- Rex has no prefix defaults, so each one is listed here.
rex.bind(p("c"), "client.tab.new")
rex.bind(p("n"), "client.tab.next")
rex.bind(p("p"), "client.tab.previous")
for i = 1, 9 do
  rex.bind(p(tostring(i)), "client.tab.goto", { index = i })
end
rex.bind(p("shift+t"), "client.tab.rename")
rex.bind(p("x"), "pane.close")
rex.bind(p("z"), "pane.zoom")
rex.bind(p("tab"), "pane.focus_next")
rex.bind(p("shift+tab"), "pane.focus_previous")
rex.bind(p("w"), "session.switch")
rex.bind(p("shift+n"), "session.new")
rex.bind(p("shift+w"), "session.rename")
rex.bind(p("shift+d"), "session.close")
rex.bind(p("b"), "client.sidebar.toggle")
rex.bind(p("s"), "client.settings")
rex.bind(p("shift+r"), "client.config.reload")
rex.bind(p("shift+/"), "client.palette.toggle")

-- Popups: a floating terminal covering 80% of the window, started in the
-- focused pane's directory. Closes when its program exits.
rex.action{
  name  = "popup",
  title = "Open Popup Terminal",
  args  = { command = "array?" },
  run   = function(ctx, args)
    local options = {}
    if ctx.block_id then
      local r = rex.block.call("com.superlogical.terminal", "pwd", { block_id = ctx.block_id })
      local path = r and r.pwd and r.pwd:match("^file://[^/]*(/.*)$")
      if path then
        options.cwd = path:gsub("%%(%x%x)", function(h) return string.char(tonumber(h, 16)) end)
      end
    end
    options.command = args.command
    local _, err = rex.session.new_layer{
      bounds = { 0.1, 0.1, 0.8, 0.8 },
      layout = rex.layout.block{ flavor = "com.superlogical.terminal.shell", options = options },
      focus  = true,
    }
    if err ~= nil then error(err, 0) end
  end,
}

-- prefix+t: scratch shell
rex.bind(p("t"), "popup")
-- cmd+r: hunk diff watcher
rex.bind("cmd+r", "popup", { command = { "hunk", "diff", "--watch" } })
