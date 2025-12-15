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

struct SelectorReceiveAssetsAddressPageItemView: View {
    @ObservedObject private(set) var viewModel: SelectorReceiveAssetsAddressPageItemViewModel

    var body: some View {
        VStack(alignment: .center, spacing: Layout.Container.verticalSpacing) {
            TokenIcon(
                tokenIconInfo: viewModel.tokenIconInfo,
                size: IconViewSizeSettings.receiveAlert.iconSize
            )

            FixedSpacer(height: Layout.Container.tokenIconTextVerticalSpacing)

            tokenContentView()

            FixedSpacer(height: Layout.Container.textQRCodeButtonVerticalSpacing)

            SelectorReceiveQRCodeButtonView(qrCodeAction: viewModel.qrCodeButtonDidTap)

            FixedSpacer(height: Layout.Container.qrCodeButtonActionsVerticalSpacing)

            SelectorReceiveRoundGroupButtonView(
                copyAction: viewModel.copyAddressButtonDidTap,
                shareAction: viewModel.shareButtonDidTap
            )
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

            Text(viewModel.address)
                .multilineTextAlignment(.center)
                .infinityFrame(axis: .horizontal, alignment: .center)
                .padding(.horizontal, Layout.TokenContentView.addressHorizontalPadding)
        }
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
