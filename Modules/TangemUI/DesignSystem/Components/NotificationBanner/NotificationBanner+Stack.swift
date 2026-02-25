//
//  NotificationBanner+Stack.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUIUtils

public struct NotificationBannerStack<Item: Identifiable, Content: View>: View {
    let items: [Item]
    @ViewBuilder let content: (Item) -> Content

    private let maxVisible: Int
    private let scaleStep: CGFloat = 0.05
    private let yOffsetStep: CGFloat = SizeUnit.x4.value
    private let swipeThreshold: CGFloat = 0.45

    @State private var currentIndex: Int = 0

    @State private var isSwiping: Bool = false
    @State private var dragOffset: CGFloat = 0
    @State private var dragProgress: CGFloat = 0

    @State private var cardSize: CGSize = .zero
    @State private var maxCardHeight: CGFloat = 0

    public init(
        items: [Item],
        maxVisibleItems: Int = 3,
        @ViewBuilder content: @escaping (Item) -> Content
    ) {
        self.items = items
        maxVisible = maxVisibleItems
        self.content = content
    }

    public var body: some View {
        VStack(spacing: SizeUnit.x5.value) {
            ZStack {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    let position = distanceFromTop(index)
                    let isTop = position == 0

                    cardView(for: item, position: position, isTop: isTop)
                        .transition(
                            .asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            )
                        )
                        .highPriorityGesture(isSwipeEnabled ? swipeGesture : nil)
                }
            }
            .onChange(of: items.count) { newCount in
                if newCount == 0 {
                    currentIndex = 0
                } else if currentIndex >= newCount {
                    currentIndex = currentIndex % newCount
                }
            }

            if items.count > 1 {
                PageIndicatorView(
                    totalPages: items.count,
                    currentIndex: currentIndex
                )
            }
        }
    }

    private func cardView(for item: Item, position: Int, isTop: Bool) -> some View {
        content(item)
            .onGeometryChange(for: CGSize.self, of: { $0.size }) { size in
                if isTop { cardSize = size }
                if size.height > maxCardHeight { maxCardHeight = size.height }
            }
            .frame(height: maxCardHeight > 0 ? maxCardHeight : nil, alignment: .bottom)
            .scaleEffect(scale(for: position), anchor: .top)
            .offset(x: isTop ? dragOffset : 0, y: yOffset(for: position))
            .opacity(position < maxVisible ? 1 : 0)
            .zIndex(Double(items.count - position))
            .animation(.smooth(duration: 0.25), value: position)
            .allowsHitTesting(isTop)
            .onAnimationTargetProgress(
                for: dragProgress,
                targetValue: 0.65,
                comparator: { lhs, rhs in
                    guard isSwiping else { return false }

                    return lhs >= rhs
                }
            ) {
                handleSwipeCompleted()
            }
    }

    private func adjustedPosition(for position: Int) -> CGFloat {
        position == 0
            ? CGFloat(position)
            : CGFloat(position) - dragProgress
    }

    private func scale(for position: Int) -> CGFloat {
        let maxScale = CGFloat(maxVisible - 1) * scaleStep
        return 1 - min(adjustedPosition(for: position) * scaleStep, maxScale)
    }

    private func yOffset(for position: Int) -> CGFloat {
        let maxOffset = CGFloat(maxVisible - 1) * yOffsetStep
        return min(adjustedPosition(for: position) * yOffsetStep, maxOffset)
    }

    private func distanceFromTop(_ index: Int) -> Int {
        let count = items.count
        guard count > 0 else { return 0 }
        let topIndex = currentIndex % count
        return (index - topIndex + count) % count
    }

    private var isSwipeEnabled: Bool {
        items.count > 1
    }

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                dragOffset = value.translation.width
                dragProgress = normalizedDragProgress()
            }
            .onEnded { value in
                let velocity = value.predictedEndTranslation.width - value.translation.width
                let shouldComplete = (abs(dragOffset) + abs(velocity) / 5) > cardSize.width * swipeThreshold

                if shouldComplete {
                    completeSwipe(
                        direction: dragOffset > 0 ? .trailing : .leading
                    )
                } else {
                    cancelSwipe()
                }
            }
    }

    private enum SwipeDirection {
        case leading
        case trailing

        var sign: CGFloat { self == .trailing ? 1 : -1 }
    }

    private func completeSwipe(direction: SwipeDirection) {
        isSwiping = true
        withAnimation(.smooth(duration: 0.25)) {
            dragOffset = direction.sign * cardSize.width
            dragProgress = 1
        }
    }

    private func handleSwipeCompleted() {
        guard isSwiping else { return }

        isSwiping = false
        currentIndex = (currentIndex + 1) % items.count
        dragProgress = 0
        withAnimation(.smooth(duration: 0.25)) {
            dragOffset = 0
        }
    }

    private func cancelSwipe() {
        withAnimation(.smooth(duration: 0.3)) {
            dragOffset = 0
            dragProgress = 0
        }
    }

    private func normalizedDragProgress() -> CGFloat {
        guard cardSize.width > 0 else { return 0 }
        return min(abs(dragOffset) / cardSize.width, 1)
    }
}
