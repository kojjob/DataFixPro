import { useEffect, useRef, useCallback, useState } from 'react';

/**
 * Custom hook for managing keyboard shortcuts
 * @param {Object} shortcuts - Object mapping shortcut keys to callback functions
 * @param {Object} options - Configuration options
 * @returns {Object} Hook utilities for scope management
 */
const useKeyboardShortcuts = (shortcuts = {}, options = {}) => {
  const {
    preventDefault = false,
    scope = 'global',
  } = options;

  const [isScopeActive, setIsScopeActive] = useState(scope === 'global');
  const shortcutsRef = useRef(shortcuts);
  const optionsRef = useRef(options);

  // Update refs when props change
  useEffect(() => {
    shortcutsRef.current = shortcuts;
    optionsRef.current = options;
  }, [shortcuts, options]);

  /**
   * Parse a shortcut string into components
   * @param {string} shortcut - e.g., "ctrl+shift+s"
   * @returns {Object} Parsed shortcut components
   */
  const parseShortcut = useCallback((shortcut) => {
    const parts = shortcut.toLowerCase().split('+');
    const key = parts[parts.length - 1];

    return {
      key,
      ctrl: parts.includes('ctrl'),
      cmd: parts.includes('cmd'),
      shift: parts.includes('shift'),
      alt: parts.includes('alt'),
      meta: parts.includes('meta') || parts.includes('cmd'),
    };
  }, []);

  /**
   * Check if a keyboard event matches a shortcut
   * @param {KeyboardEvent} event - The keyboard event
   * @param {Object} shortcut - Parsed shortcut object
   * @returns {boolean} Whether the event matches the shortcut
   */
  const matchesShortcut = useCallback((event, shortcut) => {
    const key = event.key.toLowerCase();

    // Handle special keys
    let eventKey = key;
    if (key === 'delete') eventKey = 'delete';
    if (key === 'backspace') eventKey = 'backspace';
    if (key === 'escape') eventKey = 'escape';
    if (key === 'enter') eventKey = 'enter';
    if (key === 'tab') eventKey = 'tab';
    if (key === ' ') eventKey = 'space';

    // Check if key matches
    if (eventKey !== shortcut.key) {
      return false;
    }

    // Check modifiers
    const modifiersMatch =
      (shortcut.ctrl === event.ctrlKey || (shortcut.ctrl && event.metaKey && navigator.platform.includes('Mac'))) &&
      (shortcut.cmd === event.metaKey || (shortcut.cmd && event.ctrlKey && !navigator.platform.includes('Mac'))) &&
      (shortcut.shift === event.shiftKey) &&
      (shortcut.alt === event.altKey) &&
      (shortcut.meta === event.metaKey);

    return modifiersMatch ||
           (!shortcut.ctrl && !shortcut.cmd && !shortcut.shift && !shortcut.alt && !shortcut.meta &&
            eventKey === shortcut.key);
  }, []);

  /**
   * Find the most specific matching shortcut
   * @param {KeyboardEvent} event - The keyboard event
   * @returns {string|null} The matching shortcut key or null
   */
  const findMatchingShortcut = useCallback((event) => {
    const shortcutKeys = Object.keys(shortcutsRef.current);
    let bestMatch = null;
    let bestSpecificity = -1;

    for (const shortcutKey of shortcutKeys) {
      const parsed = parseShortcut(shortcutKey);

      if (matchesShortcut(event, parsed)) {
        // Calculate specificity (more modifiers = more specific)
        const specificity =
          (parsed.ctrl ? 1 : 0) +
          (parsed.cmd ? 1 : 0) +
          (parsed.shift ? 1 : 0) +
          (parsed.alt ? 1 : 0) +
          (parsed.meta ? 1 : 0);

        if (specificity > bestSpecificity) {
          bestMatch = shortcutKey;
          bestSpecificity = specificity;
        }
      }
    }

    return bestMatch;
  }, [parseShortcut, matchesShortcut]);

  /**
   * Handle keydown events
   */
  const handleKeyDown = useCallback((event) => {
    // Check if scope is active
    if (optionsRef.current.scope !== 'global' && !isScopeActive) {
      return;
    }

    // Find matching shortcut
    const matchingShortcut = findMatchingShortcut(event);

    if (matchingShortcut && shortcutsRef.current[matchingShortcut]) {
      // Prevent default if requested
      if (optionsRef.current.preventDefault) {
        event.preventDefault();
      }

      // Call the callback
      shortcutsRef.current[matchingShortcut](event);
    }
  }, [isScopeActive, findMatchingShortcut]);

  /**
   * Activate the scope for this set of shortcuts
   */
  const activateScope = useCallback(() => {
    setIsScopeActive(true);
  }, []);

  /**
   * Deactivate the scope for this set of shortcuts
   */
  const deactivateScope = useCallback(() => {
    setIsScopeActive(false);
  }, []);

  // Set up event listeners
  useEffect(() => {
    // Add event listener
    document.addEventListener('keydown', handleKeyDown);

    // Cleanup
    return () => {
      document.removeEventListener('keydown', handleKeyDown);
    };
  }, [handleKeyDown]);

  return {
    activateScope,
    deactivateScope,
    isScopeActive,
  };
};

export default useKeyboardShortcuts;