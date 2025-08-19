//
//  SelectorReceiveAssetsDomainItemView.swift
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

struct SelectorReceiveAssetsDomainItemView: View {
    @ObservedObject private(set) var viewModel: SelectorReceiveAssetsDomainItemViewModel

    var body: some View {
        Button(action: viewModel.itemButtonDidTap) {
            HStack(spacing: Layout.Container.contentSpacing) {
                addressIconView(with: viewModel.address)

                addressContentView(value: viewModel.address)

                Spacer(minLength: .zero)

                buttonView
            }
            .padding(.vertical, Layout.Container.padding)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Private Implementation

    private func addressIconView(with address: String) -> some View {
        AddressIconView(viewModel: AddressIconViewModel(address: address))
            .frame(size: Layout.AddressIcon.bothDimensions)
    }

    private func addressContentView(value: String) -> some View {
        VStack(alignment: .center, spacing: Layout.InfoView.verticalSpacing) {
            Text(value)
                .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }

    private var buttonView: some View {
        HStack(spacing: Layout.ButtomView.horizontalSpacing) {
            Button(action: viewModel.copyAddressButtonDidTap) {
                Assets.copyNew.image
                    .renderingMode(.template)
                    .foregroundStyle(Colors.Icon.informative)
                    .padding(Layout.ButtomView.paddingIcon)
                    .background(
                        Circle()
                            .fill(Colors.Button.secondary)
                    )
                    .padding(.leading, Layout.ButtomView.paddingIconCircle)
            }
        }
    }
}

// MARK: - Layout

private extension SelectorReceiveAssetsDomainItemView {
    enum Layout {
        enum Container {
            static let padding: CGFloat = 14
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
