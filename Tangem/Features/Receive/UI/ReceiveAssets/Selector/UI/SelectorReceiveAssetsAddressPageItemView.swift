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

            tokenContentView(value: viewModel.address)

            FixedSpacer(height: Layout.Container.textQRCodeButtonVerticalSpacing)

            SelectorReceiveQRCodeButtonView(qrCodeAction: viewModel.qrCodeButtonDidTap)

            FixedSpacer(height: Layout.Container.qrCodeButtonActionsVerticalSpacing)

            SelectorReceiveRoundGroupButtonView(
                copyAction: viewModel.copyAddressButtonDidTap,
                shareAction: viewModel.shareButtonDidTap
            )
        }
        .padding(.vertical, Layout.Container.verticalPadding)
        .contentShape(Rectangle())
    }

    // MARK: - Private Implementation

    private func tokenContentView(value: String) -> some View {
        VStack(alignment: .center, spacing: Layout.TokenContentView.verticalSpacing) {
            Text(viewModel.title)
                .style(Fonts.Bold.body, color: Colors.Text.primary1)
                .lineLimit(1)

            Text(value)
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .truncationMode(.middle)
                .padding(.horizontal, Layout.TokenContentView.addressHorizontalSpacing)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Layout

private extension SelectorReceiveAssetsAddressPageItemView {
    enum Layout {
        enum Container {
            /// 32
            static let verticalPadding: CGFloat = 32

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
            static let addressHorizontalSpacing: CGFloat = 24
        }

        enum ActionsButtonView {
            /// 20
            static let topPadding: CGFloat = 20
        }
    }
}
