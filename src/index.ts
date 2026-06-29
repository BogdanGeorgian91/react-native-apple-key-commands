import { Platform } from 'react-native';
import { requireOptionalNativeModule } from 'expo-modules-core';

export type KeyModifier = 'command' | 'shift' | 'option' | 'control';
export interface KeyCommand {
  /** stable id echoed back on press */
  id: string;
  /** single char, or: return | escape | space | tab | up | down | left | right */
  input: string;
  modifiers?: KeyModifier[];
  /** shown in the iPad ⌘-hold overlay (no menu bar) */
  title?: string;
}

// In expo-modules-core (Expo 56), a native module that declares `Events(...)` IS an
// EventEmitter — call `addListener` on it directly. Constructing `new EventEmitter(module)`
// is the legacy form and types the event name as `never`.
const Native = Platform.OS === 'ios'
  ? requireOptionalNativeModule<any>('AppleKeyCommands')
  : null;

/** iOS only; false on Android / when the native module is absent (Jest). */
export function isKeyCommandsSupported(): boolean {
  return !!Native;
}

/** Register/replace the active set of key commands. No-op when unsupported. */
export function setKeyCommands(commands: KeyCommand[]): void {
  Native?.setKeyCommands(commands.map(c => ({ ...c, modifiers: c.modifiers ?? [] })));
}

/** Remove all registered key commands. No-op when unsupported. */
export function clearKeyCommands(): void {
  Native?.clearKeyCommands();
}

/** Subscribe to command presses; the callback receives the command id. */
export function addKeyCommandListener(cb: (id: string) => void): { remove(): void } {
  if (!Native) return { remove() {} };
  const sub = Native.addListener('onKeyCommand', (e: { id: string }) => cb(e.id));
  return { remove: () => sub.remove() };
}
