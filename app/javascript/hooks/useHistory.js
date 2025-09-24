import { useReducer, useCallback, useRef, useEffect } from 'react';

// Action types
const PUSH_STATE = 'PUSH_STATE';
const UNDO = 'UNDO';
const REDO = 'REDO';
const CLEAR = 'CLEAR';

// Reducer function
function historyReducer(state, action) {
  switch (action.type) {
    case PUSH_STATE: {
      const { newState, maxHistorySize } = action.payload;

      // Remove any states after current index (clear redo stack)
      const truncatedHistory = state.history.slice(0, state.currentIndex + 1);

      // Add new state
      let newHistory = [...truncatedHistory, newState];

      // Limit history size
      if (newHistory.length > maxHistorySize + 1) {
        // Keep the most recent states
        newHistory = newHistory.slice(newHistory.length - maxHistorySize - 1);
        return {
          history: newHistory,
          currentIndex: maxHistorySize
        };
      }

      return {
        history: newHistory,
        currentIndex: newHistory.length - 1
      };
    }

    case UNDO: {
      if (state.currentIndex > 0) {
        return {
          ...state,
          currentIndex: state.currentIndex - 1
        };
      }
      return state;
    }

    case REDO: {
      if (state.currentIndex < state.history.length - 1) {
        return {
          ...state,
          currentIndex: state.currentIndex + 1
        };
      }
      return state;
    }

    case CLEAR: {
      const { resetState } = action.payload;
      return {
        history: [resetState],
        currentIndex: 0
      };
    }

    default:
      return state;
  }
}

/**
 * Custom hook for managing undo/redo history
 * @param {*} initialState - Initial state value
 * @param {number} maxHistorySize - Maximum number of history states to keep (default: 50)
 * @param {Function} onChange - Callback when state changes (optional)
 * @returns {Object} History management functions and state
 */
const useHistory = (initialState, maxHistorySize = 50, onChange = null) => {
  const [state, dispatch] = useReducer(historyReducer, {
    history: [initialState],
    currentIndex: 0
  });

  // Use ref to avoid stale closure issues with callbacks
  const onChangeRef = useRef(onChange);
  onChangeRef.current = onChange;

  // Current state
  const currentState = state.history[state.currentIndex];

  // Track the previous state for onChange callback
  const prevStateRef = useRef(currentState);

  // Call onChange when currentState changes
  useEffect(() => {
    if (prevStateRef.current !== currentState && onChangeRef.current) {
      onChangeRef.current(currentState);
    }
    prevStateRef.current = currentState;
  }, [currentState]);

  /**
   * Push a new state to history
   */
  const pushState = useCallback((newState) => {
    dispatch({
      type: PUSH_STATE,
      payload: { newState, maxHistorySize }
    });
  }, [maxHistorySize]);

  /**
   * Undo to previous state
   */
  const undo = useCallback(() => {
    dispatch({ type: UNDO });
  }, []);

  /**
   * Redo to next state
   */
  const redo = useCallback(() => {
    dispatch({ type: REDO });
  }, []);

  /**
   * Clear all history and reset to initial state
   */
  const clearHistory = useCallback((newInitialState = null) => {
    const resetState = newInitialState !== null ? newInitialState : initialState;
    dispatch({
      type: CLEAR,
      payload: { resetState }
    });
  }, [initialState]);

  // Calculate derived states
  const canUndo = state.currentIndex > 0;
  const canRedo = state.currentIndex < state.history.length - 1;
  const historySize = state.history.length - 1; // Exclude initial state from count

  return {
    currentState,
    pushState,
    undo,
    redo,
    clearHistory,
    canUndo,
    canRedo,
    historySize,
    historyIndex: state.currentIndex,
  };
};

export default useHistory;