import { renderHook, act } from '@testing-library/react';
import useHistory from '../../hooks/useHistory';

describe('useHistory Hook', () => {
  describe('Initial State', () => {
    it('should initialize with empty history and current state', () => {
      const initialState = { nodes: [], edges: [] };
      const { result } = renderHook(() => useHistory(initialState));

      expect(result.current.currentState).toEqual(initialState);
      expect(result.current.canUndo).toBe(false);
      expect(result.current.canRedo).toBe(false);
      expect(result.current.historySize).toBe(0);
    });
  });

  describe('Push State', () => {
    it('should add new state to history', () => {
      const initialState = { nodes: [], edges: [] };
      const { result } = renderHook(() => useHistory(initialState));

      const newState = { nodes: ['node1'], edges: [] };

      act(() => {
        result.current.pushState(newState);
      });

      expect(result.current.currentState).toEqual(newState);
      expect(result.current.canUndo).toBe(true);
      expect(result.current.canRedo).toBe(false);
      expect(result.current.historySize).toBe(1);
    });

    it('should clear redo stack when pushing new state after undo', () => {
      const initialState = { nodes: [], edges: [] };
      const { result } = renderHook(() => useHistory(initialState));

      // Push multiple states
      act(() => {
        result.current.pushState({ nodes: ['node1'], edges: [] });
        result.current.pushState({ nodes: ['node1', 'node2'], edges: [] });
        result.current.pushState({ nodes: ['node1', 'node2', 'node3'], edges: [] });
      });

      // Undo twice
      act(() => {
        result.current.undo();
        result.current.undo();
      });

      expect(result.current.canRedo).toBe(true);

      // Push new state
      act(() => {
        result.current.pushState({ nodes: ['node1', 'node4'], edges: [] });
      });

      expect(result.current.canRedo).toBe(false);
      expect(result.current.currentState).toEqual({ nodes: ['node1', 'node4'], edges: [] });
    });

    it('should respect maximum history size of 50', () => {
      const initialState = { nodes: [], edges: [] };
      const { result } = renderHook(() => useHistory(initialState, 50));

      // Push 60 states
      act(() => {
        for (let i = 0; i < 60; i++) {
          result.current.pushState({ nodes: [`node${i}`], edges: [] });
        }
      });

      expect(result.current.historySize).toBe(50);
    });
  });

  describe('Undo Operation', () => {
    it('should revert to previous state', () => {
      const initialState = { nodes: [], edges: [] };
      const { result } = renderHook(() => useHistory(initialState));

      const state1 = { nodes: ['node1'], edges: [] };
      const state2 = { nodes: ['node1', 'node2'], edges: [] };

      act(() => {
        result.current.pushState(state1);
        result.current.pushState(state2);
      });

      act(() => {
        result.current.undo();
      });

      expect(result.current.currentState).toEqual(state1);
      expect(result.current.canUndo).toBe(true);
      expect(result.current.canRedo).toBe(true);
    });

    it('should not undo beyond initial state', () => {
      const initialState = { nodes: [], edges: [] };
      const { result } = renderHook(() => useHistory(initialState));

      act(() => {
        result.current.pushState({ nodes: ['node1'], edges: [] });
      });

      act(() => {
        result.current.undo();
        result.current.undo(); // Try to undo beyond initial
      });

      expect(result.current.currentState).toEqual(initialState);
      expect(result.current.canUndo).toBe(false);
    });

    it('should call onChange callback when undoing', () => {
      const initialState = { nodes: [], edges: [] };
      const onChange = jest.fn();
      const { result } = renderHook(() => useHistory(initialState, 50, onChange));

      const state1 = { nodes: ['node1'], edges: [] };

      act(() => {
        result.current.pushState(state1);
      });

      act(() => {
        result.current.undo();
      });

      expect(onChange).toHaveBeenCalledWith(initialState);
    });
  });

  describe('Redo Operation', () => {
    it('should restore previously undone state', () => {
      const initialState = { nodes: [], edges: [] };
      const { result } = renderHook(() => useHistory(initialState));

      const state1 = { nodes: ['node1'], edges: [] };
      const state2 = { nodes: ['node1', 'node2'], edges: [] };

      act(() => {
        result.current.pushState(state1);
        result.current.pushState(state2);
      });

      act(() => {
        result.current.undo();
      });

      act(() => {
        result.current.redo();
      });

      expect(result.current.currentState).toEqual(state2);
      expect(result.current.canUndo).toBe(true);
      expect(result.current.canRedo).toBe(false);
    });

    it('should not redo when there is nothing to redo', () => {
      const initialState = { nodes: [], edges: [] };
      const { result } = renderHook(() => useHistory(initialState));

      const state1 = { nodes: ['node1'], edges: [] };

      act(() => {
        result.current.pushState(state1);
      });

      act(() => {
        result.current.redo(); // Nothing to redo
      });

      expect(result.current.currentState).toEqual(state1);
      expect(result.current.canRedo).toBe(false);
    });

    it('should call onChange callback when redoing', () => {
      const initialState = { nodes: [], edges: [] };
      const onChange = jest.fn();
      const { result } = renderHook(() => useHistory(initialState, 50, onChange));

      const state1 = { nodes: ['node1'], edges: [] };

      act(() => {
        result.current.pushState(state1);
        result.current.undo();
      });

      onChange.mockClear();

      act(() => {
        result.current.redo();
      });

      expect(onChange).toHaveBeenCalledWith(state1);
    });
  });

  describe('Clear History', () => {
    it('should reset history to initial state', () => {
      const initialState = { nodes: [], edges: [] };
      const { result } = renderHook(() => useHistory(initialState));

      act(() => {
        result.current.pushState({ nodes: ['node1'], edges: [] });
        result.current.pushState({ nodes: ['node1', 'node2'], edges: [] });
      });

      act(() => {
        result.current.clearHistory();
      });

      expect(result.current.currentState).toEqual(initialState);
      expect(result.current.canUndo).toBe(false);
      expect(result.current.canRedo).toBe(false);
      expect(result.current.historySize).toBe(0);
    });

    it('should accept optional new initial state when clearing', () => {
      const initialState = { nodes: [], edges: [] };
      const { result } = renderHook(() => useHistory(initialState));

      act(() => {
        result.current.pushState({ nodes: ['node1'], edges: [] });
        result.current.pushState({ nodes: ['node1', 'node2'], edges: [] });
      });

      const newInitialState = { nodes: ['new'], edges: ['edge1'] };

      act(() => {
        result.current.clearHistory(newInitialState);
      });

      expect(result.current.currentState).toEqual(newInitialState);
      expect(result.current.canUndo).toBe(false);
      expect(result.current.canRedo).toBe(false);
    });
  });

  describe('History Navigation', () => {
    it('should provide history index for debugging', () => {
      const initialState = { nodes: [], edges: [] };
      const { result } = renderHook(() => useHistory(initialState));

      act(() => {
        result.current.pushState({ nodes: ['node1'], edges: [] });
        result.current.pushState({ nodes: ['node1', 'node2'], edges: [] });
      });

      expect(result.current.historyIndex).toBe(2);

      act(() => {
        result.current.undo();
      });

      expect(result.current.historyIndex).toBe(1);
    });

    it('should handle rapid state changes without loss', () => {
      const initialState = { nodes: [], edges: [] };
      const { result } = renderHook(() => useHistory(initialState));

      const states = Array.from({ length: 10 }, (_, i) => ({
        nodes: Array.from({ length: i + 1 }, (_, j) => `node${j}`),
        edges: []
      }));

      act(() => {
        states.forEach(state => result.current.pushState(state));
      });

      expect(result.current.historySize).toBe(10);
      expect(result.current.currentState).toEqual(states[9]);

      // Undo all
      act(() => {
        for (let i = 0; i < 10; i++) {
          result.current.undo();
        }
      });

      expect(result.current.currentState).toEqual(initialState);

      // Redo all
      act(() => {
        for (let i = 0; i < 10; i++) {
          result.current.redo();
        }
      });

      expect(result.current.currentState).toEqual(states[9]);
    });
  });
});