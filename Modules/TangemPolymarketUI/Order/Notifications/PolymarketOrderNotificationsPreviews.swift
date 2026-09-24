//
//  PolymarketOrderNotificationsPreviews.swift
//  TangemPolymarketUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils

private struct PolymarketOrderNotificationsShowcase: View {
    var body: some View {
        ScrollView {
            VStack(spacing: Constants.sectionSpacing) {
                section(title: "All states", notifications: PolymarketOrderNotification.allCases)

                section(
                    title: "Advisory only",
                    notifications: PolymarketOrderNotification.allCases.filter { !$0.isBlocking }
                )

                section(
                    title: "Blocking only",
                    notifications: PolymarketOrderNotification.allCases.filter(\.isBlocking)
                )
            }
            .padding(.horizontal, Constants.horizontalPadding)
            .padding(.vertical, Constants.sectionSpacing)
        }
        .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
    }

    private func section(
        title: String,
        notifications: [PolymarketOrderNotification]
    ) -> some View {
        VStack(alignment: .leading, spacing: Constants.titleSpacing) {
            Text(title)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textTertiary)

            PolymarketOrderNotificationsView(notifications: notifications)
        }
    }
}

// MARK: - Constants

private extension PolymarketOrderNotificationsShowcase {
    enum Constants {
        static let sectionSpacing: CGFloat = 32
        static let titleSpacing: CGFloat = 8
        static let horizontalPadding: CGFloat = 16
    }
}

// MARK: - Previews

#Preview("Showcase") {
    PolymarketOrderNotificationsShowcase()
}

#Preview("Showcase — Dark") {
    PolymarketOrderNotificationsShowcase()
        .preferredColorScheme(.dark)
}
