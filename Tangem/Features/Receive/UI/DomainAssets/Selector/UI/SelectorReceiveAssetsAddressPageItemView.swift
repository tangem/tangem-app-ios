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
        Button(action: viewModel.itemButtonDidTap) {
            VStack(alignment: .center, spacing: .zero) {
                mainContent

                HStack(spacing: Layout.Container.contentSpacing) {
                    addressIconView(with: viewModel.address)

                    addressContentView(header: viewModel.title, value: viewModel.address)

                    buttonView
                }
            }
            .padding(.vertical, Layout.Container.verticalPadding)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Private Implementation

    @ViewBuilder
    private var mainContent: some View {
        VStack(alignment: .center, spacing: Layout.Content.spacing) {
            TokenIcon(
                tokenIconInfo: viewModel.tokenIconInfo,
                size: IconViewSizeSettings.receiveAlert.iconSize
            )

            VStack(alignment: .center, spacing: Layout.Content.textSpacing) {
                Text(viewModel.title)
            }
        }
        .padding(.top, 12)
    }

    private func addressIconView(with address: String) -> some View {
        AddressIconView(viewModel: AddressIconViewModel(address: address))
            .frame(size: Layout.AddressIcon.bothDimensions)
    }

    private func addressContentView(header: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: Layout.InfoView.verticalSpacing) {
            Text(header)
                .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)
                .lineLimit(1)

            Text(value)
                .style(Fonts.Bold.caption1, color: Colors.Text.tertiary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var buttonView: some View {
        HStack(spacing: Layout.ButtomView.horizontalSpacing) {
            Button(action: viewModel.qrCodeButtonDidTap) {
                SelectorReceiveRoundButtonView(actionType: .qr)
            }

            Button(action: viewModel.copyAddressButtonDidTap) {
                SelectorReceiveRoundButtonView(actionType: .copy)
            }
        }
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
            /// 24
            static let spacing: CGFloat = 24
            /// 12
            static let textSpacing: CGFloat = 12
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
