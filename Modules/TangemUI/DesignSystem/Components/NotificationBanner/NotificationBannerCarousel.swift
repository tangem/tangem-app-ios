//
//  NotificationBannerCarousel.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUIUtils

public struct NotificationBannerCarousel<Item: NotificationBannerContainerItem>: View {
    let items: [Item]

    private let spacing: CGFloat = SizeUnit.x4.value
    private let swipeThreshold: CGFloat = 0.25
    private let animationDuration: TimeInterval = 0.45

    @State private var currentIndex: Int = 0

    private var safeCurrentIndex: Int {
        guard !items.isEmpty else { return 0 }
        return min(currentIndex, items.count - 1)
    }

    @State private var isSwiping: Bool = false
    @State private var targetIndex: Int = 0
    @State private var dragOffset: CGFloat = 0
    @State private var dragProgress: CGFloat = 0
    @State private var containerWidth: CGFloat = 0

    public init(items: [Item]) {
        self.items = items
    }

    public var body: some View {
        VStack(spacing: SizeUnit.x4.value) {
            ZStack {
                peekingItemView
                currentItemView
            }
            .onGeometryChange(for: CGFloat.self, of: { $0.size.width }) {
                containerWidth = $0
            }
            .clipped()
            .gesture(swipeGesture)
            .onAnimationTargetProgress(
                for: dragProgress,
                targetValue: 0.98,
                comparator: { lhs, rhs in
                    guard isSwiping else { return false }

                    return lhs >= rhs
                }
            ) {
                handleSwipeCompleted()
            }
            .onChange(of: items.count) { newCount in
                currentIndex = safeCurrentIndex
            }

            if items.count > 1 {
                TangemPagination(
                    totalPages: items.count,
                    currentIndex: safeCurrentIndex
                )
            }
        }
    }

    private var currentItemView: some View {
        bannerView(for: items[safeCurrentIndex])
            .offset(x: dragOffset)
    }

    @ViewBuilder
    private var peekingItemView: some View {
        if dragOffset != 0 {
            bannerView(for: items[peekIndex])
                .offset(x: peekOffset)
        }
    }

    private func bannerView(for item: Item) -> some View {
        NotificationBanner(bannerType: item.bannerType)
            .padding(.horizontal, SizeUnit.x4.value)
    }

    private var isSwipingForward: Bool {
        dragOffset < 0
    }

    private var peekIndex: Int {
        isSwipingForward
            ? (safeCurrentIndex + 1) % items.count
            : (safeCurrentIndex - 1 + items.count) % items.count
    }

    private var peekOffset: CGFloat {
        let pageStep = containerWidth + spacing
        return isSwipingForward
            ? pageStep + dragOffset
            : -pageStep + dragOffset
    }

    private var swipeGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                isSwiping = true
                dragOffset = value.translation.width
                dragProgress = normalizedDragProgress()
            }
            .onEnded { value in
                let velocity = value.predictedEndTranslation.width - value.translation.width
                let shouldComplete = (abs(dragOffset) + abs(velocity) / 5) > containerWidth * swipeThreshold

                if shouldComplete {
                    let isForward = dragOffset < 0
                    let newIndex = isForward
                        ? (safeCurrentIndex + 1) % items.count
                        : (safeCurrentIndex - 1 + items.count) % items.count
                    let pageStep = containerWidth + spacing
                    completeSwipe(to: newIndex, targetOffset: isForward ? -pageStep : pageStep)
                } else {
                    cancelSwipe()
                }
            }
    }

    private func completeSwipe(to newIndex: Int, targetOffset: CGFloat) {
        targetIndex = newIndex
        withAnimation(.smooth(duration: animationDuration)) {
            dragOffset = targetOffset
            dragProgress = 1
        }
    }

    private func handleSwipeCompleted() {
        guard isSwiping else { return }

        isSwiping = false
        currentIndex = targetIndex
        dragOffset = 0
        dragProgress = 0
    }

    private func cancelSwipe() {
        withAnimation(.smooth(duration: animationDuration * 0.7)) {
            isSwiping = false
            dragOffset = 0
            dragProgress = 0
        }
    }

    private func normalizedDragProgress() -> CGFloat {
        let pageStep = containerWidth + spacing
        guard pageStep > 0 else { return 0 }
        return min(abs(dragOffset) / pageStep, 1)
    }
}
