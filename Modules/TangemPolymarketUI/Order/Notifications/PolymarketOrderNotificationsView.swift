//
//  PolymarketOrderNotificationsView.swift
//  TangemPolymarketUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

public struct PolymarketOrderNotificationsView: View {
    private let notifications: [PolymarketOrderNotification]

    public init(notifications: [PolymarketOrderNotification]) {
        self.notifications = notifications
    }

    public var body: some View {
        if !notifications.isEmpty {
            VStack(spacing: Constants.spacing) {
                ForEach(notifications) {
                    banner(for: $0)
                        .transition(.opacity)
                }
            }
        }
    }

    @ViewBuilder
    private func banner(for notification: PolymarketOrderNotification) -> some View {
        let base = MessageBanner(
            title: AttributedString(notification.title),
            description: AttributedString(notification.message)
        )
        .variant(notification.variant)
        .glowRing(notification.glowRing)

        switch notification {
        case .awaitingFunds:
            base.slotEnd { Loader().loaderSize(Constants.loaderSize) }
        case .partialFill:
            base.slotEnd { infoIcon }
        case .noLiquidity:
            base.slotEnd { warningIcon }
        case .quoteUnavailable, .belowMinOrder, .marketClosed, .regionRestricted:
            base
        }
    }

    private var infoIcon: some View {
        icon(DesignSystem.Icons.Info.regular20)
    }

    private var warningIcon: some View {
        icon(DesignSystem.Icons.Warning.regular20)
    }

    private func icon(_ asset: ImageType) -> some View {
        asset.image
            .renderingMode(.template)
            .resizable()
            .frame(width: Constants.infoIconSide, height: Constants.infoIconSide)
            .foregroundStyle(DesignSystem.Color.iconPrimary)
    }
}

// MARK: - Constants

private extension PolymarketOrderNotificationsView {
    enum Constants {
        static let spacing: CGFloat = 8
        static let infoIconSide: CGFloat = 20
        static let loaderSize: Loader.Size = .size20
    }
}
