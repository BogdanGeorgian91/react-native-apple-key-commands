import { isKeyCommandsSupported, setKeyCommands, clearKeyCommands, addKeyCommandListener } from '../index';

describe('react-native-apple-key-commands (native module absent)', () => {
  it('is inert and never throws when unsupported', () => {
    expect(isKeyCommandsSupported()).toBe(false);
    expect(() => setKeyCommands([{ id: 'palette', input: 'k', modifiers: ['command'] }])).not.toThrow();
    expect(() => clearKeyCommands()).not.toThrow();
    const sub = addKeyCommandListener(() => {});
    expect(() => sub.remove()).not.toThrow();
  });
});
