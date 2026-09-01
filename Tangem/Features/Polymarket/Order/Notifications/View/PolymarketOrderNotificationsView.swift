//
//  PolymarketOrderNotificationsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

struct PolymarketOrderNotificationsView: View {
    let notifications: [PolymarketOrderNotification]
    var onRetry: (() -> Void)?

    var body: some View {
        if !notifications.isEmpty {
            VStack(spacing: Constants.spacing) {
                ForEach(notifications) { banner(for: $0) }
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
        case .partialFill, .noLiquidity:
            base.slotEnd { infoIcon }
        case .quoteUnavailable:
            if let onRetry {
                base.primaryButton(MessageBannerButton(title: Localization.commonRetry, action: onRetry))
            } else {
                base
            }
        case .belowMinOrder, .marketClosed, .regionRestricted:
            base
        }
    }

    private var infoIcon: some View {
        DesignSystem.Icons.Info.regular20.image
            .renderingMode(.template)
            .resizable()
            .frame(width: Constants.infoIconSide, height: Constants.infoIconSide)
            .foregroundStyle(DesignSystem.Color.iconPrimary)
    }
}

// MARK: - Constants

private extension PolymarketOrderNotificationsView {
    enum Constants {
        static let spacing: CGFloat = 12
        static let infoIconSide: CGFloat = 20
        static let loaderSize: Loader.Size = .size20
    }
}
