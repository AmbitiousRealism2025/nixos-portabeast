# Hyprland shortcut reference

This list reflects the declarative configuration in
`home/ambitiousrealism/hyprland.nix`. **Super** is the Windows key.

## Applications and desktop controls

| Shortcut | Action |
| --- | --- |
| `Super` + `Enter` | Open Kitty terminal |
| `Super` + `Shift` + `Enter` | Open Zen browser |
| `Super` + `Space` | Toggle DMS Spotlight launcher |
| `Super` + `Shift` + `Space` | Open Fuzzel fallback launcher |
| `Insert` | Start or stop Voxtype recording |
| `Super` + `Alt` + `Space` | Open DMS settings |
| `Super` + `Escape` | Open the power menu |
| `Super` + `Ctrl` + `L` | Lock the session |
| `Super` + `Ctrl` + `V` | Toggle clipboard history |
| `Super` + `Ctrl` + `Space` | Open wallpaper controls |
| `Print Screen` | Select a region, save it, and copy it to the clipboard |

## Window management

| Shortcut | Action |
| --- | --- |
| `Super` + `Q` | Close the focused window |
| `Super` + `T` | Toggle floating mode |
| `Super` + `P` | Toggle pseudo-tiling |
| `Super` + `W` | Toggle fullscreen |
| `Super` + `F` | Toggle maximized mode |
| `Super` + `H` | Focus the window to the left |
| `Super` + `J` | Focus the window above |
| `Super` + `K` | Focus the window below |
| `Super` + `L` | Focus the window to the right |
| `Super` + `Shift` + `H` | Move the focused window left |
| `Super` + `Shift` + `J` | Move the focused window up |
| `Super` + `Shift` + `K` | Move the focused window down |
| `Super` + `Shift` + `L` | Move the focused window right |
| `Alt` + `Tab` | Focus the next window |
| `Alt` + `Shift` + `Tab` | Focus the previous window |
| `Super` + left mouse button | Drag a window |
| `Super` + right mouse button | Resize a window |

## Workspaces

| Shortcut | Action |
| --- | --- |
| `Super` + `1` … `9` | Switch to workspace 1 … 9 |
| `Super` + `Shift` + `1` … `9` | Move the focused window to workspace 1 … 9 |
| `Super` + `Tab` | Switch to the next workspace on the focused monitor |
| `Super` + `Shift` + `Tab` | Switch to the previous workspace on the focused monitor |
| `Super` + mouse wheel down | Switch to the next workspace |
| `Super` + mouse wheel up | Switch to the previous workspace |

## Editing shortcuts

These bindings translate an Alt-based, Mac-style shortcut into the standard
Ctrl shortcut for the focused application. Physical `Ctrl` + `C` remains
available for terminal interrupts.

| Shortcut | Sent to the application |
| --- | --- |
| `Alt` + `C` | Copy (`Ctrl` + `C`) |
| `Alt` + `V` | Paste (`Ctrl` + `V`) |
| `Alt` + `X` | Cut (`Ctrl` + `X`) |
| `Alt` + `Z` | Undo (`Ctrl` + `Z`) |

Kitty also provides `Alt` + `Shift` + `C` for copy and
`Alt` + `Shift` + `V` for paste.

## Hardware keys

| Key | Action |
| --- | --- |
| Volume up/down | Adjust output volume by 5% |
| Audio mute | Toggle output mute |
| Microphone mute | Toggle microphone mute |
| Brightness up/down | Adjust display brightness by 5% |

## Automatic lid actions

- Closing the lid with an external monitor connected enters clamshell mode.
- Opening the lid restores the laptop display to the right of the external
  monitor.
- Without an external monitor, normal system suspend handling remains in
  control.
