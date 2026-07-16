//
//  RedesignedSelectorReceiveAssetsAddressPageItemView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import Foundation
import TangemUI
import TangemAssets
import TangemLocalization

struct RedesignedSelectorReceiveAssetsAddressPageItemView: View {
    @ObservedObject private(set) var viewModel: SelectorReceiveAssetsAddressPageItemViewModel

    var body: some View {
        VStack(alignment: .center, spacing: .zero) {
            TokenIcon(
                tokenIconInfo: viewModel.tokenIconInfo,
                size: IconViewSizeSettings.receiveAlert.iconSize
            )

            if viewModel.isDynamicAddressesEnabled {
                FixedSpacer(height: Layout.badgeSpacing)

                dynamicAddressesBadgeView

                FixedSpacer(height: Layout.badgeSpacing)
            } else {
                FixedSpacer(height: Layout.stackSpacing)
            }

            tokenContentView

            FixedSpacer(height: 8)

            qrCodeButton

            FixedSpacer(height: 20)

            actionsButtons
        }
        .padding(Layout.cardPadding)
    }

    // MARK: - Private Implementation

    private var qrCodeButton: some View {
        // [REDACTED_TODO_COMMENT]
        TangemButtonV2(
            label: AttributedString(Localization.tokenReceiveShowQrCodeTitle),
            iconStart: Assets.Receive.qrButtonIcon,
            accessibilityLabel: Localization.tokenReceiveShowQrCodeTitle,
            action: viewModel.qrCodeButtonDidTap
        )
        .size(.x10)
        .styleType(.ghost)
        .disabled(viewModel.isLoading)
    }

    private var actionsButtons: some View {
        HStack(spacing: 8) {
            TangemButtonV2(
                label: AttributedString(Localization.commonCopy),
                iconStart: DesignSystem.Icons.Copy.regular24,
                accessibilityLabel: Localization.commonCopy,
                action: viewModel.copyAddressButtonDidTap
            )
            .size(.x12)
            .styleType(.secondary)

            TangemButtonV2(
                label: AttributedString(Localization.commonShare),
                iconStart: DesignSystem.Icons.ShareIos.regular24,
                accessibilityLabel: Localization.commonShare,
                action: viewModel.shareButtonDidTap
            )
            .size(.x12)
            .styleType(.secondary)
        }
        .disabled(viewModel.isLoading)
    }

    private var tokenContentView: some View {
        VStack(alignment: .center, spacing: 4) {
            Text(viewModel.title)
                .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
                .lineLimit(1)

            if viewModel.isLoading {
                SkeletonView()
                    .frame(width: 80, height: 14)
                    .cornerRadiusContinuous(4)
            } else {
                Text(viewModel.address)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .infinityFrame(axis: .horizontal, alignment: .center)
            }
        }
        .padding(.horizontal, 24)
    }

    private var dynamicAddressesBadgeView: some View {
        TangemBadgeV2(label: Localization.dynamicAddressesReceiveBadge, accessibilityLabel: nil)
            .size(.x6)
            .variant(.tinted)
            .appearance(.info)
            // [REDACTED_TODO_COMMENT]
            .slotStart(Assets.dynamicAddressesRowsIcon)
    }
}

// MARK: - Layout

private extension RedesignedSelectorReceiveAssetsAddressPageItemView {
    enum Layout {
        static let cardPadding: CGFloat = 16
        static let stackSpacing: CGFloat = 12
        static let badgeSpacing: CGFloat = 16
    }
}
