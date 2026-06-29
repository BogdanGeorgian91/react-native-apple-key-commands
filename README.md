# react-native-apple-key-commands

> ☕ **If this library has helped you, consider [buying me a coffee](https://buymeacoffee.com/boogdan)!** Your support keeps development going.

Dynamic hardware-keyboard shortcuts (UIKeyCommand) for React Native and Expo. Register key commands from JavaScript, get an event back when one fires. Works on iPad with a connected keyboard and on iPad apps running on an Apple silicon Mac. iOS only, built with the Expo Modules API.

```ts
import { setKeyCommands, addKeyCommandListener } from 'react-native-apple-key-commands';

setKeyCommands([{ id: 'launch', input: 'return', modifiers: ['command'], title: 'Launch' }]);
const sub = addKeyCommandListener(id => { if (id === 'launch') runSearch(); });
```

## Why

React Native and Expo expose no API for hardware-keyboard shortcuts. On iPad (and iPad apps running on Mac), UIKit has a first-class mechanism for this: `UIKeyCommand`. This module bridges it -- commands are defined dynamically from JavaScript (not hardcoded native), and a single JS event fires when any registered command is pressed.

Note: **there is no menu bar integration.** The `title` field feeds only the iPad ⌘-hold discoverbility overlay; `UIMenuBuilder` and the macOS menu bar are not involved.

## Installation

```bash
npm install react-native-apple-key-commands
# or
yarn add react-native-apple-key-commands
# or
bun add react-native-apple-key-commands
```

Then rebuild the native project so autolinking picks up the module:

```bash
npx expo prebuild
npx expo run:ios
```

There is **no config plugin and no entitlements** to set up -- installing and rebuilding is all that is required.

### Prerequisites

- Expo `>= 51.0.0`
- React Native `>= 0.74.0`
- iOS only (Android and other platforms are safely inert -- see [Platform behavior](#platform-behavior))
- A native build. Key commands register and fire on a device or simulator build; in Jest the native module is absent and all helpers no-op.

## API Reference

```ts
import {
  setKeyCommands,
  clearKeyCommands,
  addKeyCommandListener,
  isKeyCommandsSupported,
} from 'react-native-apple-key-commands';
import type { KeyCommand, KeyModifier } from 'react-native-apple-key-commands';
```

### Types

```ts
type KeyModifier = 'command' | 'shift' | 'option' | 'control';

interface KeyCommand {
  /** Stable id echoed back to the listener when this command fires. */
  id: string;
  /**
   * The key to bind. Use a single character, or one of the named keys:
   * return | escape | space | tab | up | down | left | right
   */
  input: string;
  modifiers?: KeyModifier[];
  /** Shown in the iPad ⌘-hold overlay. No effect on the menu bar. */
  title?: string;
}
```

### `setKeyCommands(commands)`

```ts
function setKeyCommands(commands: KeyCommand[]): void;
```

Registers (or replaces) the full set of active key commands. The previous set is removed before the new one is applied. No-op when the native module is unavailable (Android, Jest).

### `clearKeyCommands()`

```ts
function clearKeyCommands(): void;
```

Removes all currently registered key commands. No-op when unsupported.

### `addKeyCommandListener(cb)`

```ts
function addKeyCommandListener(cb: (id: string) => void): { remove(): void };
```

Subscribes to key command presses. The callback receives the `id` of the command that fired. Returns an object with a `remove()` method to unsubscribe. When the native module is unavailable, the callback is never called and `remove()` is a no-op.

### `isKeyCommandsSupported()`

```ts
function isKeyCommandsSupported(): boolean;
```

Returns `true` on iOS when the native module is loaded, `false` otherwise (Android, Jest). Use this to conditionally render keyboard-shortcut hints.

## Example: a default key map

A full key map defined entirely from JavaScript -- no native rebuild needed when commands change:

```ts
import { setKeyCommands, addKeyCommandListener } from 'react-native-apple-key-commands';
import { useEffect } from 'react';

const KEY_MAP = [
  { id: 'launch',   input: 'return', modifiers: ['command'],        title: 'Launch search'    },
  { id: 'palette',  input: 'k',      modifiers: ['command'],        title: 'Open palette'     },
  { id: 'copy',     input: 'c',      modifiers: ['command'],        title: 'Copy query'       },
  { id: 'dismiss',  input: 'escape', modifiers: [],                 title: 'Dismiss'          },
  { id: 'engine1',  input: '1',      modifiers: ['option'],         title: 'Engine 1'         },
  { id: 'engine2',  input: '2',      modifiers: ['option'],         title: 'Engine 2'         },
  { id: 'engine3',  input: '3',      modifiers: ['option'],         title: 'Engine 3'         },
  { id: 'engine4',  input: '4',      modifiers: ['option'],         title: 'Engine 4'         },
  { id: 'engine5',  input: '5',      modifiers: ['option'],         title: 'Engine 5'         },
  { id: 'engine6',  input: '6',      modifiers: ['option'],         title: 'Engine 6'         },
  { id: 'engine7',  input: '7',      modifiers: ['option'],         title: 'Engine 7'         },
  { id: 'engine8',  input: '8',      modifiers: ['option'],         title: 'Engine 8'         },
];

export function useKeyMap(handlers: Record<string, () => void>) {
  useEffect(() => {
    setKeyCommands(KEY_MAP);
    const sub = addKeyCommandListener(id => handlers[id]?.());
    return () => { sub.remove(); };
  }, []);
}
```

> **Note:** bare `escape` and `return` (no modifier) may be swallowed by a focused text field. Commands with a `command` modifier fire reliably even while text input is active.

## Platform behavior

| Environment                          | Commands fire | Listener fires |
| ------------------------------------ | :-----------: | :------------: |
| iPad with keyboard                   |      yes      |      yes       |
| iPad app on Mac (Apple silicon)      |      yes      |      yes       |
| iPhone / no keyboard                 |      no       |       no       |
| Android                              |      no       |       no       |
| Jest / no native runtime             |      no       |       no       |

All exports are safe to call on any platform. On non-iOS and when the native module is absent (Jest), `setKeyCommands` and `clearKeyCommands` are no-ops, `addKeyCommandListener` returns a no-op `{ remove() {} }`, and `isKeyCommandsSupported()` returns `false`.

## How it works

When `setKeyCommands` is called, the native module dispatches to the main thread and attaches `UIKeyCommand` objects to the root view controller of the key window (`rootViewController.addKeyCommand`). Each command stores its `id` in `UIKeyCommand.propertyList`.

The first call installs a single action method (`ak_handleKeyCommand:`) on the root view controller class at runtime using `class_addMethod`. Because the method is on the view controller (not a text field), it sits above focused responders in the responder chain -- ⌘-modified commands reach it even while a text field has first responder. When the action fires, the module reads the `id` from `propertyList` and emits an `onKeyCommand` event to JavaScript.

There is no `UIMenuBuilder` involvement and no macOS menu bar integration. The `title` field controls only the discoverbility label shown in the iPad ⌘-hold overlay.

## License

MIT © [Bogdan Georgian Alexa](https://github.com/BogdanGeorgian91)
