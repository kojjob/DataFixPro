import { renderHook, act } from '@testing-library/react';
import { fireEvent } from '@testing-library/dom';
import useKeyboardShortcuts from '../../hooks/useKeyboardShortcuts';

describe('useKeyboardShortcuts Hook', () => {
  let container;

  beforeEach(() => {
    // Create a container element for testing
    container = document.createElement('div');
    document.body.appendChild(container);
  });

  afterEach(() => {
    // Clean up
    document.body.removeChild(container);
  });

  describe('Keyboard Event Registration', () => {
    it('should register shortcuts on mount', () => {
      const shortcuts = {
        'ctrl+z': jest.fn(),
        'ctrl+shift+z': jest.fn(),
      };

      renderHook(() => useKeyboardShortcuts(shortcuts));

      // Simulate Ctrl+Z
      fireEvent.keyDown(document, {
        key: 'z',
        ctrlKey: true,
        shiftKey: false,
      });

      expect(shortcuts['ctrl+z']).toHaveBeenCalledTimes(1);
      expect(shortcuts['ctrl+shift+z']).not.toHaveBeenCalled();
    });

    it('should handle multiple modifiers correctly', () => {
      const shortcuts = {
        'ctrl+shift+s': jest.fn(),
        'ctrl+s': jest.fn(),
      };

      renderHook(() => useKeyboardShortcuts(shortcuts));

      // Simulate Ctrl+Shift+S
      fireEvent.keyDown(document, {
        key: 's',
        ctrlKey: true,
        shiftKey: true,
      });

      expect(shortcuts['ctrl+shift+s']).toHaveBeenCalledTimes(1);
      expect(shortcuts['ctrl+s']).not.toHaveBeenCalled();
    });

    it('should support cmd key as alternative to ctrl on Mac', () => {
      const shortcuts = {
        'cmd+z': jest.fn(),
        'ctrl+z': jest.fn(),
      };

      renderHook(() => useKeyboardShortcuts(shortcuts));

      // Simulate Cmd+Z (Mac)
      fireEvent.keyDown(document, {
        key: 'z',
        metaKey: true,
        ctrlKey: false,
      });

      expect(shortcuts['cmd+z']).toHaveBeenCalledTimes(1);
      expect(shortcuts['ctrl+z']).not.toHaveBeenCalled();
    });

    it('should handle Delete key without modifiers', () => {
      const shortcuts = {
        'delete': jest.fn(),
        'backspace': jest.fn(),
      };

      renderHook(() => useKeyboardShortcuts(shortcuts));

      // Simulate Delete key
      fireEvent.keyDown(document, {
        key: 'Delete',
      });

      expect(shortcuts['delete']).toHaveBeenCalledTimes(1);

      // Simulate Backspace key
      fireEvent.keyDown(document, {
        key: 'Backspace',
      });

      expect(shortcuts['backspace']).toHaveBeenCalledTimes(1);
    });
  });

  describe('Event Callback Parameters', () => {
    it('should pass event object to callback', () => {
      const mockCallback = jest.fn();
      const shortcuts = {
        'ctrl+s': mockCallback,
      };

      renderHook(() => useKeyboardShortcuts(shortcuts));

      const event = new KeyboardEvent('keydown', {
        key: 's',
        ctrlKey: true,
      });

      fireEvent(document, event);

      expect(mockCallback).toHaveBeenCalledWith(expect.objectContaining({
        key: 's',
        ctrlKey: true,
      }));
    });

    it('should prevent default behavior when preventDefault option is true', () => {
      const mockCallback = jest.fn();
      const shortcuts = {
        'ctrl+s': mockCallback,
      };

      const options = {
        preventDefault: true,
      };

      renderHook(() => useKeyboardShortcuts(shortcuts, options));

      const event = new KeyboardEvent('keydown', {
        key: 's',
        ctrlKey: true,
        cancelable: true,
      });

      const preventDefaultSpy = jest.spyOn(event, 'preventDefault');

      fireEvent(document, event);

      expect(preventDefaultSpy).toHaveBeenCalled();
      expect(mockCallback).toHaveBeenCalled();
    });

    it('should not prevent default when preventDefault option is false', () => {
      const mockCallback = jest.fn();
      const shortcuts = {
        'ctrl+s': mockCallback,
      };

      const options = {
        preventDefault: false,
      };

      renderHook(() => useKeyboardShortcuts(shortcuts, options));

      const event = new KeyboardEvent('keydown', {
        key: 's',
        ctrlKey: true,
        cancelable: true,
      });

      const preventDefaultSpy = jest.spyOn(event, 'preventDefault');

      fireEvent(document, event);

      expect(preventDefaultSpy).not.toHaveBeenCalled();
      expect(mockCallback).toHaveBeenCalled();
    });
  });

  describe('Scope Management', () => {
    it('should only trigger shortcuts when scope is active', () => {
      const mockCallback = jest.fn();
      const shortcuts = {
        'ctrl+z': mockCallback,
      };

      const options = {
        scope: 'editor',
      };

      const { result } = renderHook(() => useKeyboardShortcuts(shortcuts, options));

      // Initially, scope is inactive
      fireEvent.keyDown(document, {
        key: 'z',
        ctrlKey: true,
      });

      expect(mockCallback).not.toHaveBeenCalled();

      // Activate scope
      act(() => {
        result.current.activateScope();
      });

      fireEvent.keyDown(document, {
        key: 'z',
        ctrlKey: true,
      });

      expect(mockCallback).toHaveBeenCalledTimes(1);

      // Deactivate scope
      act(() => {
        result.current.deactivateScope();
      });

      fireEvent.keyDown(document, {
        key: 'z',
        ctrlKey: true,
      });

      expect(mockCallback).toHaveBeenCalledTimes(1); // Still 1, not called again
    });

    it('should handle global scope (always active)', () => {
      const mockCallback = jest.fn();
      const shortcuts = {
        'escape': mockCallback,
      };

      const options = {
        scope: 'global',
      };

      renderHook(() => useKeyboardShortcuts(shortcuts, options));

      fireEvent.keyDown(document, {
        key: 'Escape',
      });

      expect(mockCallback).toHaveBeenCalledTimes(1);
    });
  });

  describe('Cleanup', () => {
    it('should remove event listeners on unmount', () => {
      const mockCallback = jest.fn();
      const shortcuts = {
        'ctrl+z': mockCallback,
      };

      const { unmount } = renderHook(() => useKeyboardShortcuts(shortcuts));

      // Unmount the hook
      unmount();

      // Try to trigger shortcut after unmount
      fireEvent.keyDown(document, {
        key: 'z',
        ctrlKey: true,
      });

      expect(mockCallback).not.toHaveBeenCalled();
    });

    it('should update shortcuts when dependencies change', () => {
      const callback1 = jest.fn();
      const callback2 = jest.fn();

      const initialShortcuts = {
        'ctrl+a': callback1,
      };

      const { rerender } = renderHook(
        ({ shortcuts }) => useKeyboardShortcuts(shortcuts),
        { initialProps: { shortcuts: initialShortcuts } }
      );

      // Test initial shortcut
      fireEvent.keyDown(document, {
        key: 'a',
        ctrlKey: true,
      });

      expect(callback1).toHaveBeenCalledTimes(1);

      // Update shortcuts
      const newShortcuts = {
        'ctrl+b': callback2,
      };

      rerender({ shortcuts: newShortcuts });

      // Old shortcut should not work
      fireEvent.keyDown(document, {
        key: 'a',
        ctrlKey: true,
      });

      expect(callback1).toHaveBeenCalledTimes(1); // Still 1

      // New shortcut should work
      fireEvent.keyDown(document, {
        key: 'b',
        ctrlKey: true,
      });

      expect(callback2).toHaveBeenCalledTimes(1);
    });
  });

  describe('Common Shortcuts', () => {
    it('should handle common undo/redo shortcuts', () => {
      const undo = jest.fn();
      const redo = jest.fn();

      const shortcuts = {
        'ctrl+z': undo,
        'cmd+z': undo,
        'ctrl+y': redo,
        'cmd+y': redo,
        'ctrl+shift+z': redo,
        'cmd+shift+z': redo,
      };

      renderHook(() => useKeyboardShortcuts(shortcuts));

      // Test undo (Ctrl+Z)
      fireEvent.keyDown(document, {
        key: 'z',
        ctrlKey: true,
      });
      expect(undo).toHaveBeenCalledTimes(1);

      // Test redo (Ctrl+Y)
      fireEvent.keyDown(document, {
        key: 'y',
        ctrlKey: true,
      });
      expect(redo).toHaveBeenCalledTimes(1);

      // Test redo (Ctrl+Shift+Z)
      fireEvent.keyDown(document, {
        key: 'z',
        ctrlKey: true,
        shiftKey: true,
      });
      expect(redo).toHaveBeenCalledTimes(2);
    });

    it('should handle save shortcut', () => {
      const save = jest.fn();

      const shortcuts = {
        'ctrl+s': save,
        'cmd+s': save,
      };

      renderHook(() => useKeyboardShortcuts(shortcuts, { preventDefault: true }));

      const event = new KeyboardEvent('keydown', {
        key: 's',
        ctrlKey: true,
        cancelable: true,
      });

      const preventDefaultSpy = jest.spyOn(event, 'preventDefault');

      fireEvent(document, event);

      expect(save).toHaveBeenCalledTimes(1);
      expect(preventDefaultSpy).toHaveBeenCalled(); // Prevent browser save dialog
    });

    it('should handle delete shortcut for selected items', () => {
      const deleteSelected = jest.fn();

      const shortcuts = {
        'delete': deleteSelected,
        'backspace': deleteSelected,
      };

      renderHook(() => useKeyboardShortcuts(shortcuts));

      fireEvent.keyDown(document, {
        key: 'Delete',
      });

      expect(deleteSelected).toHaveBeenCalledTimes(1);

      fireEvent.keyDown(document, {
        key: 'Backspace',
      });

      expect(deleteSelected).toHaveBeenCalledTimes(2);
    });

    it('should handle duplicate shortcut', () => {
      const duplicate = jest.fn();

      const shortcuts = {
        'ctrl+d': duplicate,
        'cmd+d': duplicate,
      };

      renderHook(() => useKeyboardShortcuts(shortcuts, { preventDefault: true }));

      fireEvent.keyDown(document, {
        key: 'd',
        ctrlKey: true,
      });

      expect(duplicate).toHaveBeenCalledTimes(1);
    });
  });

  describe('Conflict Resolution', () => {
    it('should handle conflicting shortcuts by specificity', () => {
      const genericCallback = jest.fn();
      const specificCallback = jest.fn();

      const shortcuts = {
        'ctrl': genericCallback, // Less specific
        'ctrl+s': specificCallback, // More specific
      };

      renderHook(() => useKeyboardShortcuts(shortcuts));

      fireEvent.keyDown(document, {
        key: 's',
        ctrlKey: true,
      });

      // More specific shortcut should be called
      expect(specificCallback).toHaveBeenCalledTimes(1);
      expect(genericCallback).not.toHaveBeenCalled();
    });
  });
});