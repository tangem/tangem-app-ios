//
//  SelectorReceiveAssetsAddressItemView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization

struct SelectorReceiveAssetsAddressItemView: View {
    @ObservedObject private(set) var viewModel: SelectorReceiveAssetsAddressItemViewModel

    var body: some View {
        Button(action: viewModel.itemButtonDidTap) {
            HStack(spacing: Layout.Container.contentSpacing) {
                addressIconView(with: viewModel.address)

                addressContentView(header: viewModel.header, value: viewModel.address)

                buttonView
            }
            .padding(.vertical, Layout.Container.verticalPadding)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Private Implementation

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
    }

    private var buttonView: some View {
        HStack(spacing: Layout.ButtomView.horizontalSpacing) {
            Button(action: viewModel.qrCodeButtonDidTap) {
                Assets.qrNew.image
                    .renderingMode(.template)
                    .resizable()
                    .frame(size: .init(bothDimensions: 20))
                    .foregroundStyle(Colors.Icon.informative)
                    .padding(Layout.ButtomView.paddingIcon)
                    .background(
                        Circle()
                            .fill(Colors.Button.secondary)
                    )
                    .padding(Layout.ButtomView.paddingIconCircle)
            }

            Button(action: viewModel.copyAddressButtonDidTap) {
                Assets.copyNew.image
                    .renderingMode(.template)
                    .frame(size: .init(bothDimensions: 20))
                    .foregroundStyle(Colors.Icon.informative)
                    .padding(Layout.ButtomView.paddingIcon)
                    .background(
                        Circle()
                            .fill(Colors.Button.secondary)
                    )
                    .padding(Layout.ButtomView.paddingIconCircle)
            }
        }
    }
}

// MARK: - Layout

private extension SelectorReceiveAssetsAddressItemView {
    enum Layout {
        enum Container {
            static let verticalPadding: CGFloat = 14
            static let contentSpacing: CGFloat = 12
        }

        enum InfoView {
            static let verticalSpacing: CGFloat = 2
        }

        enum ButtomView {
            static let horizontalSpacing: CGFloat = 8
            static let paddingIcon: CGFloat = 8
            static let paddingIconCircle: CGFloat = 2
        }

        enum AddressIcon {
            static let bothDimensions: CGSize = .init(bothDimensions: 36)
        }
    }
}
