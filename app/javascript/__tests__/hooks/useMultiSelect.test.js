import { renderHook, act } from '@testing-library/react';
import useMultiSelect from '../../hooks/useMultiSelect';

describe('useMultiSelect Hook', () => {
  const mockNodes = [
    { id: '1', position: { x: 0, y: 0 }, data: { label: 'Node 1' } },
    { id: '2', position: { x: 100, y: 0 }, data: { label: 'Node 2' } },
    { id: '3', position: { x: 200, y: 0 }, data: { label: 'Node 3' } },
    { id: '4', position: { x: 0, y: 100 }, data: { label: 'Node 4' } },
    { id: '5', position: { x: 100, y: 100 }, data: { label: 'Node 5' } },
  ];

  describe('Initial State', () => {
    it('should initialize with empty selection', () => {
      const { result } = renderHook(() => useMultiSelect(mockNodes));

      expect(result.current.selectedNodeIds).toEqual([]);
      expect(result.current.isMultiSelectMode).toBe(false);
      expect(result.current.selectionBox).toBeNull();
    });
  });

  describe('Single Node Selection', () => {
    it('should select a single node', () => {
      const { result } = renderHook(() => useMultiSelect(mockNodes));

      act(() => {
        result.current.selectNode('1');
      });

      expect(result.current.selectedNodeIds).toEqual(['1']);
      expect(result.current.isNodeSelected('1')).toBe(true);
      expect(result.current.isNodeSelected('2')).toBe(false);
    });

    it('should replace selection when selecting new node without modifier', () => {
      const { result } = renderHook(() => useMultiSelect(mockNodes));

      act(() => {
        result.current.selectNode('1');
      });

      act(() => {
        result.current.selectNode('2');
      });

      expect(result.current.selectedNodeIds).toEqual(['2']);
      expect(result.current.isNodeSelected('1')).toBe(false);
      expect(result.current.isNodeSelected('2')).toBe(true);
    });

    it('should toggle selection when node is already selected', () => {
      const { result } = renderHook(() => useMultiSelect(mockNodes));

      act(() => {
        result.current.selectNode('1');
      });

      act(() => {
        result.current.toggleNode('1');
      });

      expect(result.current.selectedNodeIds).toEqual([]);
      expect(result.current.isNodeSelected('1')).toBe(false);
    });
  });

  describe('Multiple Node Selection', () => {
    it('should add node to selection with addToSelection', () => {
      const { result } = renderHook(() => useMultiSelect(mockNodes));

      act(() => {
        result.current.selectNode('1');
      });

      act(() => {
        result.current.addToSelection('2');
      });

      expect(result.current.selectedNodeIds).toEqual(['1', '2']);
      expect(result.current.isNodeSelected('1')).toBe(true);
      expect(result.current.isNodeSelected('2')).toBe(true);
    });

    it('should toggle node in selection', () => {
      const { result } = renderHook(() => useMultiSelect(mockNodes));

      act(() => {
        result.current.selectNode('1');
        result.current.addToSelection('2');
      });

      act(() => {
        result.current.toggleNode('2');
      });

      expect(result.current.selectedNodeIds).toEqual(['1']);
    });

    it('should select multiple nodes at once', () => {
      const { result } = renderHook(() => useMultiSelect(mockNodes));

      act(() => {
        result.current.selectNodes(['1', '3', '5']);
      });

      expect(result.current.selectedNodeIds).toEqual(['1', '3', '5']);
      expect(result.current.selectedNodes).toHaveLength(3);
      expect(result.current.selectedNodes[0].id).toBe('1');
      expect(result.current.selectedNodes[1].id).toBe('3');
      expect(result.current.selectedNodes[2].id).toBe('5');
    });

    it('should clear all selections', () => {
      const { result } = renderHook(() => useMultiSelect(mockNodes));

      act(() => {
        result.current.selectNodes(['1', '2', '3']);
      });

      act(() => {
        result.current.clearSelection();
      });

      expect(result.current.selectedNodeIds).toEqual([]);
      expect(result.current.selectedNodes).toEqual([]);
    });

    it('should select all nodes', () => {
      const { result } = renderHook(() => useMultiSelect(mockNodes));

      act(() => {
        result.current.selectAll();
      });

      expect(result.current.selectedNodeIds).toHaveLength(5);
      expect(result.current.selectedNodeIds).toEqual(['1', '2', '3', '4', '5']);
    });
  });

  describe('Selection Box', () => {
    it('should start selection box', () => {
      const { result } = renderHook(() => useMultiSelect(mockNodes));

      const startPoint = { x: 10, y: 20 };

      act(() => {
        result.current.startSelectionBox(startPoint);
      });

      expect(result.current.isMultiSelectMode).toBe(true);
      expect(result.current.selectionBox).toEqual({
        startX: 10,
        startY: 20,
        endX: 10,
        endY: 20,
        x: 10,
        y: 20,
        width: 0,
        height: 0,
      });
    });

    it('should update selection box', () => {
      const { result } = renderHook(() => useMultiSelect(mockNodes));

      const startPoint = { x: 10, y: 20 };
      const endPoint = { x: 150, y: 120 };

      act(() => {
        result.current.startSelectionBox(startPoint);
      });

      act(() => {
        result.current.updateSelectionBox(endPoint);
      });

      expect(result.current.selectionBox).toEqual({
        startX: 10,
        startY: 20,
        endX: 150,
        endY: 120,
        x: 10,
        y: 20,
        width: 140,
        height: 100,
      });
    });

    it('should handle selection box with negative dimensions', () => {
      const { result } = renderHook(() => useMultiSelect(mockNodes));

      const startPoint = { x: 150, y: 120 };
      const endPoint = { x: 10, y: 20 };

      act(() => {
        result.current.startSelectionBox(startPoint);
      });

      act(() => {
        result.current.updateSelectionBox(endPoint);
      });

      expect(result.current.selectionBox).toEqual({
        startX: 150,
        startY: 120,
        endX: 10,
        endY: 20,
        x: 10, // Min x
        y: 20, // Min y
        width: 140,
        height: 100,
      });
    });

    it('should select nodes within selection box', () => {
      const { result } = renderHook(() => useMultiSelect(mockNodes));

      act(() => {
        result.current.startSelectionBox({ x: -10, y: -10 });
      });

      act(() => {
        result.current.updateSelectionBox({ x: 110, y: 110 });
      });

      act(() => {
        result.current.endSelectionBox();
      });

      // Nodes 1, 2, 4, and 5 should be selected (within or intersecting the box)
      expect(result.current.selectedNodeIds).toContain('1');
      expect(result.current.selectedNodeIds).toContain('2');
      expect(result.current.selectedNodeIds).toContain('4');
      expect(result.current.selectedNodeIds).toContain('5');
      expect(result.current.isMultiSelectMode).toBe(false);
      expect(result.current.selectionBox).toBeNull();
    });

    it('should cancel selection box', () => {
      const { result } = renderHook(() => useMultiSelect(mockNodes));

      act(() => {
        result.current.selectNode('1'); // Pre-select a node
      });

      act(() => {
        result.current.startSelectionBox({ x: 10, y: 20 });
      });

      act(() => {
        result.current.cancelSelectionBox();
      });

      expect(result.current.isMultiSelectMode).toBe(false);
      expect(result.current.selectionBox).toBeNull();
      expect(result.current.selectedNodeIds).toEqual(['1']); // Previous selection preserved
    });
  });

  describe('Bulk Operations', () => {
    it('should delete selected nodes', () => {
      const onDelete = jest.fn();
      const { result } = renderHook(() => useMultiSelect(mockNodes, { onDelete }));

      act(() => {
        result.current.selectNodes(['1', '3']);
      });

      act(() => {
        result.current.deleteSelected();
      });

      expect(onDelete).toHaveBeenCalledWith(['1', '3']);
      expect(result.current.selectedNodeIds).toEqual([]);
    });

    it('should duplicate selected nodes', () => {
      const onDuplicate = jest.fn();
      const { result } = renderHook(() => useMultiSelect(mockNodes, { onDuplicate }));

      act(() => {
        result.current.selectNodes(['2', '4']);
      });

      act(() => {
        result.current.duplicateSelected();
      });

      expect(onDuplicate).toHaveBeenCalledWith(['2', '4']);
      // Selection remains after duplication
      expect(result.current.selectedNodeIds).toEqual(['2', '4']);
    });

    it('should move selected nodes', () => {
      const onMove = jest.fn();
      const { result } = renderHook(() => useMultiSelect(mockNodes, { onMove }));

      act(() => {
        result.current.selectNodes(['1', '2', '3']);
      });

      const delta = { dx: 50, dy: -20 };

      act(() => {
        result.current.moveSelected(delta);
      });

      expect(onMove).toHaveBeenCalledWith(['1', '2', '3'], delta);
    });

    it('should not perform operations when no nodes selected', () => {
      const onDelete = jest.fn();
      const onDuplicate = jest.fn();
      const { result } = renderHook(() => useMultiSelect(mockNodes, { onDelete, onDuplicate }));

      act(() => {
        result.current.deleteSelected();
      });

      act(() => {
        result.current.duplicateSelected();
      });

      expect(onDelete).not.toHaveBeenCalled();
      expect(onDuplicate).not.toHaveBeenCalled();
    });
  });

  describe('Node Filtering', () => {
    it('should filter selected nodes by type', () => {
      const nodesWithTypes = [
        { id: '1', type: 'datasource', position: { x: 0, y: 0 }, data: {} },
        { id: '2', type: 'transform', position: { x: 100, y: 0 }, data: {} },
        { id: '3', type: 'datasource', position: { x: 200, y: 0 }, data: {} },
        { id: '4', type: 'output', position: { x: 0, y: 100 }, data: {} },
      ];

      const { result } = renderHook(() => useMultiSelect(nodesWithTypes));

      act(() => {
        result.current.selectAll();
      });

      const datasourceNodes = result.current.getSelectedNodesByType('datasource');
      expect(datasourceNodes).toHaveLength(2);
      expect(datasourceNodes[0].id).toBe('1');
      expect(datasourceNodes[1].id).toBe('3');
    });
  });

  describe('Selection State', () => {
    it('should provide selection count', () => {
      const { result } = renderHook(() => useMultiSelect(mockNodes));

      expect(result.current.selectionCount).toBe(0);

      act(() => {
        result.current.selectNodes(['1', '2', '3']);
      });

      expect(result.current.selectionCount).toBe(3);
    });

    it('should indicate if any nodes are selected', () => {
      const { result } = renderHook(() => useMultiSelect(mockNodes));

      expect(result.current.hasSelection).toBe(false);

      act(() => {
        result.current.selectNode('1');
      });

      expect(result.current.hasSelection).toBe(true);

      act(() => {
        result.current.clearSelection();
      });

      expect(result.current.hasSelection).toBe(false);
    });
  });

  describe('Edge Cases', () => {
    it('should handle selecting non-existent node', () => {
      const { result } = renderHook(() => useMultiSelect(mockNodes));

      act(() => {
        result.current.selectNode('non-existent');
      });

      expect(result.current.selectedNodeIds).toEqual([]);
    });

    it('should handle empty nodes array', () => {
      const { result } = renderHook(() => useMultiSelect([]));

      act(() => {
        result.current.selectAll();
      });

      expect(result.current.selectedNodeIds).toEqual([]);
    });

    it('should update when nodes prop changes', () => {
      const { result, rerender } = renderHook(
        ({ nodes }) => useMultiSelect(nodes),
        { initialProps: { nodes: mockNodes } }
      );

      act(() => {
        result.current.selectNodes(['1', '2']);
      });

      const newNodes = mockNodes.slice(0, 3); // Only first 3 nodes

      rerender({ nodes: newNodes });

      // Selection should be preserved for existing nodes
      expect(result.current.selectedNodeIds).toEqual(['1', '2']);
      expect(result.current.selectedNodes).toHaveLength(2);
    });
  });
});