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
        VStack(alignment: .center, spacing: .zero) {
            mainContent

            SelectorReceiveRoundGroupButtonView(
                copyAction: viewModel.copyAddressButtonDidTap,
                shareAction: viewModel.qrCodeButtonDidTap
            )
        }
        .padding(.vertical, Layout.Container.verticalPadding)
        .contentShape(Rectangle())
    }

    // MARK: - Private Implementation

    @ViewBuilder
    private var mainContent: some View {
        VStack(alignment: .center, spacing: Layout.Content.spacing) {
            TokenIcon(
                tokenIconInfo: viewModel.tokenIconInfo,
                size: IconViewSizeSettings.receiveAlert.iconSize
            )

            tokenContentView(value: viewModel.address)
        }
        .padding(.top, 12)
    }

    private func tokenContentView(value: String) -> some View {
        VStack(alignment: .center, spacing: Layout.InfoView.verticalSpacing) {
            Text(viewModel.title)
                .style(Fonts.Bold.body, color: Colors.Text.primary1)
                .lineLimit(1)

            Text(value)
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                .lineLimit(1)
                .truncationMode(.middle)
                .padding(.horizontal, Layout.Content.addressHorizontalSpacing)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Layout

private extension SelectorReceiveAssetsAddressPageItemView {
    enum Layout {
        enum Container {
            static let verticalPadding: CGFloat = 14
            static let contentSpacing: CGFloat = 12
        }

        enum Icon {
            static let size: CGFloat = 20
        }

        enum Content {
            /// 12
            static let spacing: CGFloat = 12

            /// 24
            static let addressHorizontalSpacing: CGFloat = 24
        }

        enum InfoView {
            static let verticalSpacing: CGFloat = 2
        }

        enum ButtomView {
            static let horizontalSpacing: CGFloat = 8
        }

        enum AddressIcon {
            static let bothDimensions: CGSize = .init(bothDimensions: 36)
        }
    }
}
