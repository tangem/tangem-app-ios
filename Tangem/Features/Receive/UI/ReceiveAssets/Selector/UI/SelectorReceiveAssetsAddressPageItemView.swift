//
//  SelectorReceiveAssetsAddressPageItemView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import Foundation
import TangemUI
import TangemAssets
import TangemLocalization

struct SelectorReceiveAssetsAddressPageItemView: View {
    @ObservedObject private(set) var viewModel: SelectorReceiveAssetsAddressPageItemViewModel

    var body: some View {
        VStack(alignment: .center, spacing: Layout.Container.verticalSpacing) {
            TokenIcon(
                tokenIconInfo: viewModel.tokenIconInfo,
                size: IconViewSizeSettings.receiveAlert.iconSize
            )

            FixedSpacer(height: Layout.Container.tokenIconTextVerticalSpacing)

            if viewModel.isDynamicAddressesEnabled {
                dynamicAddressesBadgeView()

                FixedSpacer(height: Layout.Container.tokenIconTextVerticalSpacing)
            }

            tokenContentView()

            FixedSpacer(height: Layout.Container.textQRCodeButtonVerticalSpacing)

            SelectorReceiveQRCodeButtonView(qrCodeAction: viewModel.qrCodeButtonDidTap)
                .disabled(viewModel.isLoading)

            FixedSpacer(height: Layout.Container.qrCodeButtonActionsVerticalSpacing)

            SelectorReceiveRoundGroupButtonView(
                copyAction: viewModel.copyAddressButtonDidTap,
                shareAction: viewModel.shareButtonDidTap
            )
            .disabled(viewModel.isLoading)
        }
        .defaultRoundedBackground(
            with: Colors.Background.action,
            verticalPadding: Layout.Container.verticalPadding,
            horizontalPadding: Layout.Container.horizontalPadding
        )
    }

    // MARK: - Private Implementation

    private func tokenContentView() -> some View {
        VStack(alignment: .center, spacing: Layout.TokenContentView.verticalSpacing) {
            Text(viewModel.title)
                .style(Fonts.Bold.body, color: Colors.Text.primary1)
                .lineLimit(1)

            if viewModel.isLoading {
                SkeletonView()
                    .frame(width: 80, height: 14)
                    .cornerRadiusContinuous(4)
            } else {
                Text(viewModel.address)
                    .multilineTextAlignment(.center)
                    .infinityFrame(axis: .horizontal, alignment: .center)
                    .padding(.horizontal, Layout.TokenContentView.addressHorizontalPadding)
            }
        }
    }

    private func dynamicAddressesBadgeView() -> some View {
        HStack(alignment: .center, spacing: 4) {
            Assets.dynamicAddressesRowsIcon.image
                .renderingMode(.template)
                .resizable()
                .frame(width: 16, height: 16)
                .foregroundStyle(Colors.Icon.accent)
                .padding(.leading, 6)

            Text(Localization.dynamicAddressesReceiveBadge)
                .style(Fonts.Bold.caption1, color: Colors.Text.accent)
                .padding(.trailing, 10)
        }
        .padding(.vertical, 4)
        .background(Colors.Text.accent.opacity(0.1))
        .clipShape(Capsule())
    }
}

// MARK: - Layout

private extension SelectorReceiveAssetsAddressPageItemView {
    enum Layout {
        enum Container {
            /// 32
            static let verticalPadding: CGFloat = 32

            /// 12
            static let horizontalPadding: CGFloat = 12

            /// 0
            static let verticalSpacing: CGFloat = .zero

            /// 12
            static let tokenIconTextVerticalSpacing: CGFloat = 12

            /// 8
            static let textQRCodeButtonVerticalSpacing: CGFloat = 8

            /// 20
            static let qrCodeButtonActionsVerticalSpacing: CGFloat = 20
        }

        enum TokenContentView {
            /// 4
            static let verticalSpacing: CGFloat = 4
            /// 24
            static let addressHorizontalPadding: CGFloat = 16
        }

        enum ActionsButtonView {
            /// 20
            static let topPadding: CGFloat = 20
        }
    }
}
