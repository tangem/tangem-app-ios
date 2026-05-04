//
//  NotificationBannerCarousel.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUIUtils

public struct NotificationBannerCarousel<Item, BannerView: View>: View {
    let items: [Item]
    let bannerView: (Item) -> BannerView

    private let spacing: CGFloat = SizeUnit.x4.value
    private let swipeThreshold: CGFloat = 0.25
    private let animationDuration: TimeInterval = 0.45
    private var paginationHasBackground: Bool = true
    private var currentIndexHasChanged: ((Int) -> Void)?

    @State private var currentIndex: Int = 0 {
        didSet { currentIndexHasChanged?(currentIndex) }
    }

    private var safeCurrentIndex: Int {
        guard !items.isEmpty else { return 0 }
        return min(currentIndex, items.count - 1)
    }

    @State private var isSwiping: Bool = false
    @State private var targetIndex: Int = 0
    @State private var dragOffset: CGFloat = 0
    @State private var dragProgress: CGFloat = 0
    @State private var containerWidth: CGFloat = 0
    @State private var itemHeights: [Int: CGFloat] = [:]

    public init(items: [Item], @ViewBuilder bannerView: @escaping (Item) -> BannerView) {
        self.items = items
        self.bannerView = bannerView
    }

    public var body: some View {
        if items.isEmpty {
            EmptyView()
        } else {
            content
        }
    }

    private var content: some View {
        VStack(spacing: SizeUnit.x4.value) {
            ZStack(alignment: .top) {
                peekingItemView
                currentItemView
            }
            .onGeometryChange(for: CGFloat.self, of: { $0.size.width }) { width in
                containerWidth = width
            }
            .frame(height: interpolatedHeight, alignment: .top)
            .clipShape(RoundedRectangle(cornerRadius: SizeUnit.x6.value))
            .if(items.count > 1, transform: { $0.highPriorityGesture(swipeGesture) })
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
                    currentIndex: safeCurrentIndex,
                    hasBackground: paginationHasBackground
                )
            }
        }
    }

    private var currentItemView: some View {
        bannerView(for: items[safeCurrentIndex])
            .onGeometryChange(for: CGFloat.self, of: { $0.size.height }) { height in
                itemHeights[safeCurrentIndex] = height
            }
            .offset(x: dragOffset)
    }

    @ViewBuilder
    private var peekingItemView: some View {
        if dragOffset != 0 {
            bannerView(for: items[peekIndex])
                .onGeometryChange(for: CGFloat.self, of: { $0.size.height }) { height in
                    itemHeights[peekIndex] = height
                }
                .offset(x: peekOffset)
        }
    }

    private func bannerView(for item: Item) -> some View {
        bannerView(item)
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

    private var interpolatedHeight: CGFloat? {
        let currentHeight = itemHeights[safeCurrentIndex]
        guard dragOffset != 0 else {
            return currentHeight
        }

        let peekHeight = itemHeights[peekIndex]
        guard let currentHeight, let peekHeight else {
            return currentHeight ?? peekHeight
        }

        let progress = abs(dragProgress)
        let interpolatedHeight = currentHeight + (peekHeight - currentHeight) * progress
        return interpolatedHeight.rounded()
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

// MARK: - Setupable

extension NotificationBannerCarousel: Setupable {
    public func paginationHasBackground(_ background: Bool) -> Self {
        map { $0.paginationHasBackground = background }
    }

    public func currentIndexHasChanged(_ changed: ((Int) -> Void)?) -> Self {
        map { $0.currentIndexHasChanged = changed }
    }
}

// MARK: - NotificationBanner implementation

public extension NotificationBannerCarousel where Item: NotificationBannerContainerItem, BannerView == NotificationBanner {
    init(items: [Item]) {
        self.items = items
        bannerView = { item in
            NotificationBanner(bannerType: item.bannerType)
        }
    }
}
