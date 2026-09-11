//
//  NotificationBannerContainer.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

public protocol NotificationBannerContainerItem: Identifiable {
    var bannerType: NotificationBanner.BannerType { get }
    var variant: MessageBannerVariant? { get }
    var ring: NotificationBanner.Ring? { get }
    var priority: NotificationBanner.Priority { get }
    /// Overrides the default `bannerType.isStackable` decision for this specific item; `nil` keeps the default.
    var stackableOverride: Bool? { get }
    var accessibilityIdentifier: String? { get }
}

public extension NotificationBannerContainerItem {
    var variant: MessageBannerVariant? { nil }
    var ring: NotificationBanner.Ring? { nil }
    var accessibilityIdentifier: String? { nil }
    var priority: NotificationBanner.Priority { .mid }
    var stackableOverride: Bool? { nil }
}

public enum NotificaitonBannerContainerStackingType {
    case carousel
    case stack
}

public struct NotificationBannerContainer<Item: NotificationBannerContainerItem>: View {
    let items: [Item]
    let stackingType: NotificaitonBannerContainerStackingType

    private var nonStackableItems: [Item] {
        sortedByPriority(items.filter { !isStackable($0) })
    }

    private var stackableItems: [Item] {
        sortedByPriority(items.filter { isStackable($0) })
    }

    private func isStackable(_ item: Item) -> Bool {
        item.stackableOverride ?? item.bannerType.isStackable
    }

    private func underlayCornerRadius(for item: Item) -> CGFloat {
        if case .buttons = item.bannerType.bannerAction {
            return MessageBannerMetrics.cornerRadiusWithButtons
        }

        return MessageBannerMetrics.cornerRadius
    }

    private func sortedByPriority(_ items: [Item]) -> [Item] {
        items
            .enumerated()
            .sorted { lhs, rhs in
                lhs.element.priority != rhs.element.priority
                    ? lhs.element.priority > rhs.element.priority
                    : lhs.offset < rhs.offset
            }
            .map(\.element)
    }

    public init(items: [Item], stackingType: NotificaitonBannerContainerStackingType) {
        self.items = items
        self.stackingType = stackingType
    }

    public var body: some View {
        if items.isEmpty {
            EmptyView()
        } else {
            LazyVStack(spacing: SizeUnit.x2.value) {
                ForEach(nonStackableItems) { item in
                    NotificationMessageBanner(
                        bannerType: item.bannerType,
                        variant: item.variant,
                        ring: item.ring,
                        accessibilityIdentifier: item.accessibilityIdentifier
                    )
                }

                if !stackableItems.isEmpty {
                    collection(for: stackableItems)
                }
            }
        }
    }

    @ViewBuilder
    private func collection(for items: [Item]) -> some View {
        switch stackingType {
        case .carousel:
            NotificationBannerCarousel(items: items) { item in
                NotificationMessageBanner(
                    bannerType: item.bannerType,
                    variant: item.variant,
                    ring: item.ring,
                    accessibilityIdentifier: item.accessibilityIdentifier
                )
            }
            .hasClipShape(false)

        case .stack:
            NotificationBannerStack(items: items) { item, isTop in
                NotificationMessageBanner(
                    bannerType: item.bannerType,
                    variant: item.variant,
                    ring: isTop ? item.ring : NotificationBanner.Ring.off,
                    accessibilityIdentifier: item.accessibilityIdentifier
                )
                .background(
                    DesignSystem.Color.bgSecondary,
                    in: RoundedRectangle(cornerRadius: underlayCornerRadius(for: item), style: .continuous)
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
