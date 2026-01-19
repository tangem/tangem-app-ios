//
//  MobileSettingsUpgradeBannerView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets

struct MobileSettingsUpgradeBannerView: View {
    let item: MobileSettingsUpgradeBannerItem

    var body: some View {
        VStack(spacing: 0) {
            Text(item.title)
                .style(Fonts.Bold.title2, color: Colors.Text.primary1)
                .padding(.horizontal, 24)

            Text(item.description)
                .style(Fonts.Regular.subheadline, color: Colors.Text.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)
                .padding(.horizontal, 24)

            HorizontalFlowLayout(
                items: item.chips,
                alignment: .center,
                horizontalSpacing: 16,
                verticalSpacing: 8,
                itemContent: chip
            )
            .padding(.top, 16)

            MainButton(
                title: item.action.title,
                style: .secondary,
                action: item.action.handler
            )
            .padding(.top, 4)
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 14)
        .background(Colors.Background.primary)
        .cornerRadius(14, corners: .allCorners)
        .colorScheme(.dark)
    }
}

// MARK: - Subviews

private extension MobileSettingsUpgradeBannerView {
    func chip(item: MobileSettingsUpgradeBannerItem.ChipItem) -> some View {
        HStack(alignment: .top, spacing: 6) {
            item.icon.image
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundStyle(Colors.Icon.accent)
                .frame(width: 16, height: 16)

            Text(item.title)
                .style(Fonts.Bold.footnote, color: Colors.Text.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

struct MobileSettingsUpgradeBannerItem {
    let title: String
    let description: String
    let chips: [ChipItem]
    let action: ActionItem

    struct ChipItem: Hashable {
        let title: String
        let icon: ImageType
    }

    struct ActionItem {
        let title: String
        let handler: () -> Void
    }
}
