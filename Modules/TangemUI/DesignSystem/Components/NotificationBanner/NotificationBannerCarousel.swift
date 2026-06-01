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

    private var hasClipShape: Bool = true
    private var paginationHasBackground: Bool = true
    private var currentIndexHasChanged: ((Int) -> Void)?

    @State private var currentIndex: Int = 0
    @State private var itemHeights: [Int: CGFloat] = [:]
    @State private var containerWidth: CGFloat = 0
    @State private var dragTranslation: CGFloat = 0

    private var safeCurrentIndex: Int {
        guard !items.isEmpty else { return 0 }
        return min(currentIndex, items.count - 1)
    }

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
        let wrappedItems = items.enumerated().map { IndexedItem(index: $0.offset, item: $0.element) }

        return VStack(spacing: SizeUnit.x4.value) {
            TangemCarousel(wrappedItems) { wrappedItem in
                bannerView(wrappedItem.item)
                    .onGeometryChange(for: CGFloat.self, of: { $0.size.height }) { height in
                        itemHeights[wrappedItem.index] = height
                    }
            }
            .isEndless(true)
            .interItemSpacing(SizeUnit.x4.value)
            .hidePagination()
            .currentIndexHasChanged { index in
                currentIndex = index
                currentIndexHasChanged?(index)
            }
            .onTranslationChanged { translation in
                dragTranslation = translation
            }
            .onGeometryChange(for: CGFloat.self, of: { $0.size.width }) { width in
                containerWidth = width
            }
            .frame(height: interpolatedHeight, alignment: .top)
            .if(hasClipShape) { $0.clipShape(RoundedRectangle(cornerRadius: SizeUnit.x6.value)) }

            if items.count > 1 {
                TangemPagination(
                    totalPages: items.count,
                    currentIndex: safeCurrentIndex,
                    hasBackground: paginationHasBackground
                )
                .animation(nil, value: items.count)
            }
        }
        .onChange(of: items.count) { _ in
            var transaction = Transaction(animation: nil)
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                currentIndex = safeCurrentIndex
            }
        }
    }
}

// MARK: - Height interpolation

private extension NotificationBannerCarousel {
    var interpolatedHeight: CGFloat? {
        let currentHeight = itemHeights[currentIndex]

        guard dragTranslation != 0, containerWidth > 0 else {
            return currentHeight
        }

        let isForward = dragTranslation < 0
        let adjacentIndex: Int
        if isForward {
            adjacentIndex = (currentIndex + 1) % items.count
        } else {
            adjacentIndex = (currentIndex - 1 + items.count) % items.count
        }

        let adjacentHeight = itemHeights[adjacentIndex]

        guard let currentHeight, let adjacentHeight else {
            return currentHeight ?? adjacentHeight
        }

        let progress = min(abs(dragTranslation) / containerWidth, 1)
        return (currentHeight + (adjacentHeight - currentHeight) * progress).rounded()
    }
}

// MARK: - IndexedItem

private extension NotificationBannerCarousel {
    struct IndexedItem: Identifiable, Hashable {
        let index: Int
        let item: Item

        var id: Int { index }

        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.index == rhs.index
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(index)
        }
    }
}

// MARK: - Setupable

extension NotificationBannerCarousel: Setupable {
    public func hasClipShape(_ clip: Bool) -> Self {
        map { $0.hasClipShape = clip }
    }

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
            NotificationBanner(
                bannerType: item.bannerType,
                accessibilityIdentifier: item.accessibilityIdentifier
            )
        }
    }
}
