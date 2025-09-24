import { useState, useCallback, useMemo } from 'react';

/**
 * Custom hook for managing multi-selection of nodes
 * @param {Array} nodes - Array of node objects
 * @param {Object} options - Optional configuration
 * @returns {Object} Multi-select state and methods
 */
const useMultiSelect = (nodes = [], options = {}) => {
  const { onDelete, onDuplicate, onMove } = options;

  const [selectedNodeIds, setSelectedNodeIds] = useState([]);
  const [selectionBox, setSelectionBox] = useState(null);
  const [isMultiSelectMode, setIsMultiSelectMode] = useState(false);

  /**
   * Get selected node objects
   */
  const selectedNodes = useMemo(() => {
    return nodes.filter(node => selectedNodeIds.includes(node.id));
  }, [nodes, selectedNodeIds]);

  /**
   * Get count of selected nodes
   */
  const selectionCount = selectedNodeIds.length;

  /**
   * Check if any nodes are selected
   */
  const hasSelection = selectionCount > 0;

  /**
   * Get history index (for navigation)
   */
  const historyIndex = 0; // This would integrate with history system

  /**
   * Check if a node is selected
   */
  const isNodeSelected = useCallback((nodeId) => {
    return selectedNodeIds.includes(nodeId);
  }, [selectedNodeIds]);

  /**
   * Select a single node (replaces current selection)
   */
  const selectNode = useCallback((nodeId) => {
    const node = nodes.find(n => n.id === nodeId);
    if (node) {
      setSelectedNodeIds([nodeId]);
    }
  }, [nodes]);

  /**
   * Add a node to the current selection
   */
  const addToSelection = useCallback((nodeId) => {
    const node = nodes.find(n => n.id === nodeId);
    if (node && !selectedNodeIds.includes(nodeId)) {
      setSelectedNodeIds(prev => [...prev, nodeId]);
    }
  }, [nodes, selectedNodeIds]);

  /**
   * Toggle a node's selection state
   */
  const toggleNode = useCallback((nodeId) => {
    setSelectedNodeIds(prev => {
      if (prev.includes(nodeId)) {
        return prev.filter(id => id !== nodeId);
      } else {
        const node = nodes.find(n => n.id === nodeId);
        if (node) {
          return [...prev, nodeId];
        }
        return prev;
      }
    });
  }, [nodes]);

  /**
   * Select multiple nodes
   */
  const selectNodes = useCallback((nodeIds) => {
    const validIds = nodeIds.filter(id =>
      nodes.some(node => node.id === id)
    );
    setSelectedNodeIds(validIds);
  }, [nodes]);

  /**
   * Select all nodes
   */
  const selectAll = useCallback(() => {
    setSelectedNodeIds(nodes.map(node => node.id));
  }, [nodes]);

  /**
   * Clear all selections
   */
  const clearSelection = useCallback(() => {
    setSelectedNodeIds([]);
  }, []);

  /**
   * Start selection box
   */
  const startSelectionBox = useCallback((point) => {
    setIsMultiSelectMode(true);
    setSelectionBox({
      startX: point.x,
      startY: point.y,
      endX: point.x,
      endY: point.y,
      x: point.x,
      y: point.y,
      width: 0,
      height: 0,
    });
  }, []);

  /**
   * Update selection box
   */
  const updateSelectionBox = useCallback((point) => {
    if (!selectionBox) return;

    const minX = Math.min(selectionBox.startX, point.x);
    const minY = Math.min(selectionBox.startY, point.y);
    const maxX = Math.max(selectionBox.startX, point.x);
    const maxY = Math.max(selectionBox.startY, point.y);

    setSelectionBox({
      ...selectionBox,
      endX: point.x,
      endY: point.y,
      x: minX,
      y: minY,
      width: maxX - minX,
      height: maxY - minY,
    });
  }, [selectionBox]);

  /**
   * End selection box and select nodes within it
   */
  const endSelectionBox = useCallback(() => {
    if (!selectionBox) return;

    // Select nodes that are within or intersecting the selection box
    const selectedIds = nodes
      .filter(node => {
        const nodeX = node.position.x;
        const nodeY = node.position.y;

        // Simple intersection check (assuming nodes have some size)
        // In a real implementation, you'd use actual node dimensions
        const nodeWidth = 50; // Default node width
        const nodeHeight = 50; // Default node height

        const nodeRight = nodeX + nodeWidth;
        const nodeBottom = nodeY + nodeHeight;
        const boxRight = selectionBox.x + selectionBox.width;
        const boxBottom = selectionBox.y + selectionBox.height;

        // Check if node intersects with selection box
        return !(nodeX > boxRight ||
                nodeRight < selectionBox.x ||
                nodeY > boxBottom ||
                nodeBottom < selectionBox.y);
      })
      .map(node => node.id);

    setSelectedNodeIds(selectedIds);
    setSelectionBox(null);
    setIsMultiSelectMode(false);
  }, [selectionBox, nodes]);

  /**
   * Cancel selection box
   */
  const cancelSelectionBox = useCallback(() => {
    setSelectionBox(null);
    setIsMultiSelectMode(false);
  }, []);

  /**
   * Delete selected nodes
   */
  const deleteSelected = useCallback(() => {
    if (selectedNodeIds.length > 0 && onDelete) {
      onDelete(selectedNodeIds);
      clearSelection();
    }
  }, [selectedNodeIds, onDelete, clearSelection]);

  /**
   * Duplicate selected nodes
   */
  const duplicateSelected = useCallback(() => {
    if (selectedNodeIds.length > 0 && onDuplicate) {
      onDuplicate(selectedNodeIds);
      // Keep selection after duplication
    }
  }, [selectedNodeIds, onDuplicate]);

  /**
   * Move selected nodes
   */
  const moveSelected = useCallback((delta) => {
    if (selectedNodeIds.length > 0 && onMove) {
      onMove(selectedNodeIds, delta);
    }
  }, [selectedNodeIds, onMove]);

  /**
   * Get selected nodes by type
   */
  const getSelectedNodesByType = useCallback((type) => {
    return selectedNodes.filter(node => node.type === type);
  }, [selectedNodes]);

  return {
    // State
    selectedNodeIds,
    selectedNodes,
    selectionBox,
    isMultiSelectMode,
    selectionCount,
    hasSelection,
    historyIndex,

    // Methods
    isNodeSelected,
    selectNode,
    addToSelection,
    toggleNode,
    selectNodes,
    selectAll,
    clearSelection,

    // Selection box
    startSelectionBox,
    updateSelectionBox,
    endSelectionBox,
    cancelSelectionBox,

    // Bulk operations
    deleteSelected,
    duplicateSelected,
    moveSelected,

    // Utilities
    getSelectedNodesByType,
  };
};

export default useMultiSelect;