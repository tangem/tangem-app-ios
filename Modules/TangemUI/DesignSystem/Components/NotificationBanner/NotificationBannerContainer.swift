//
//  NotificationBannerContainer.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

public protocol NotificationBannerContainerItem: Identifiable {
    var bannerType: NotificationBanner.BannerType { get }
}

public enum NotificaitonBannerContainerStackingType {
    case carousel
    case stack
}

public struct NotificationBannerContainer<Item: NotificationBannerContainerItem>: View {
    let items: [Item]
    let stackingType: NotificaitonBannerContainerStackingType

    private var nonStackableItems: [Item] {
        items.filter { !$0.bannerType.isStackable }
    }

    private var stackableItems: [Item] {
        items.filter { $0.bannerType.isStackable }
    }

    public init(items: [Item], stackingType: NotificaitonBannerContainerStackingType) {
        self.items = items
        self.stackingType = stackingType
    }

    public var body: some View {
        LazyVStack(spacing: SizeUnit.x4.value) {
            ForEach(nonStackableItems) { item in
                NotificationBanner(
                    bannerType: item.bannerType
                )
                .padding(.horizontal, SizeUnit.x4.value)
            }

            if !stackableItems.isEmpty {
                collection(for: stackableItems)
            }
        }
    }

    @ViewBuilder
    private func collection(for items: [Item]) -> some View {
        switch stackingType {
        case .carousel:
            NotificationBannerCarousel(items: items)

        case .stack:
            NotificationBannerStack(items: items) { item in
                NotificationBanner(
                    bannerType: item.bannerType
                )
                .transition(
                    .asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .opacity
                    )
                )
                .padding(.horizontal, SizeUnit.x4.value)
            }
        }
    }
}
