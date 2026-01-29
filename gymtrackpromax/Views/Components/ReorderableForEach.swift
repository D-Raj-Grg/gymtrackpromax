//
//  ReorderableForEach.swift
//  GymTrack Pro
//
//  Created by Claude Code on 29/01/26.
//

import SwiftUI

// MARK: - Drag Handle

struct ReorderDragHandle: View {
    var body: some View {
        Rectangle()
            .fill(Color.clear)
            .frame(width: 44, height: 44)
            .overlay {
                Image(systemName: "line.3.horizontal")
                    .font(.caption)
                    .foregroundStyle(Color.gymTextMuted)
                    .frame(width: 20)
            }
            .contentShape(Rectangle())
    }
}

// MARK: - ReorderableForEach

struct ReorderableForEach<Item: Identifiable, Content: View>: View where Item.ID: Hashable {
    let items: [Item]
    let isReordering: Binding<Bool>
    let onMove: (IndexSet, Int) -> Void
    @ViewBuilder let content: (Item, AnyView) -> Content

    @State private var draggedItemID: Item.ID?
    @State private var dragOffset: CGFloat = 0
    @State private var sourceIndex: Int?
    @State private var currentDestIndex: Int?

    private let rowHeight: CGFloat = 72
    private let spacing: CGFloat = AppSpacing.small

    var body: some View {
        VStack(spacing: spacing) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                let isDragged = draggedItemID == item.id

                let handle = AnyView(
                    ReorderDragHandle()
                        .gesture(dragGesture(index: index, item: item))
                )

                content(item, handle)
                    .frame(maxWidth: .infinity)
                    .zIndex(isDragged ? 100 : 0)
                    .shadow(
                        color: isDragged ? .black.opacity(0.3) : .clear,
                        radius: isDragged ? 8 : 0,
                        y: isDragged ? 4 : 0
                    )
                    .offset(y: yOffset(for: index, itemID: item.id))
            }
        }
    }

    // MARK: - Gesture

    private func dragGesture(index: Int, item: Item) -> some Gesture {
        LongPressGesture(minimumDuration: 0.25)
            .sequenced(before: DragGesture(coordinateSpace: .global))
            .onChanged { value in
                switch value {
                case .second(true, let drag):
                    if draggedItemID == nil {
                        draggedItemID = item.id
                        sourceIndex = index
                        currentDestIndex = index
                        isReordering.wrappedValue = true
                        HapticManager.mediumImpact()
                    }
                    if let drag = drag, let src = sourceIndex {
                        dragOffset = drag.translation.height
                        let newDest = destIndex(from: src, offset: dragOffset)
                        if newDest != currentDestIndex {
                            currentDestIndex = newDest
                            HapticManager.selection()
                        }
                    }
                default:
                    break
                }
            }
            .onEnded { _ in
                drop()
            }
    }

    // MARK: - Drop

    private func drop() {
        guard let src = sourceIndex, let dest = currentDestIndex else {
            resetState()
            return
        }

        // Kill all animations — commit move + reset in a single
        // non-animated transaction so nothing fights.
        var t = Transaction()
        t.disablesAnimations = true
        withTransaction(t) {
            if src != dest {
                let moveTo = dest > src ? dest + 1 : dest
                onMove(IndexSet(integer: src), moveTo)
            }
            draggedItemID = nil
            dragOffset = 0
            sourceIndex = nil
            currentDestIndex = nil
            isReordering.wrappedValue = false
        }

        HapticManager.lightImpact()
    }

    private func resetState() {
        var t = Transaction()
        t.disablesAnimations = true
        withTransaction(t) {
            draggedItemID = nil
            dragOffset = 0
            sourceIndex = nil
            currentDestIndex = nil
            isReordering.wrappedValue = false
        }
    }

    // MARK: - Offset

    private var step: CGFloat { rowHeight + spacing }

    private func yOffset(for index: Int, itemID: Item.ID) -> CGFloat {
        if itemID == draggedItemID {
            return dragOffset
        }
        guard let src = sourceIndex, let dest = currentDestIndex, src != dest else {
            return 0
        }
        if src < dest, index > src, index <= dest {
            return -step
        }
        if src > dest, index >= dest, index < src {
            return step
        }
        return 0
    }

    private func destIndex(from src: Int, offset: CGFloat) -> Int {
        let steps = Int((offset / step).rounded())
        return min(max(src + steps, 0), items.count - 1)
    }
}
