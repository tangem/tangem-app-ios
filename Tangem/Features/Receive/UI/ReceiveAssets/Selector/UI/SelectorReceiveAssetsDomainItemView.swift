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
        VStack(alignment: .leading, spacing: .zero) {
            HStack(spacing: Layout.Container.contentSpacing) {
                addressIconView(with: viewModel.address)

                addressContentView(value: viewModel.address)

                Spacer(minLength: .zero)

                buttonView
            }
        }
        .defaultRoundedBackground(
            with: Colors.Background.action,
            verticalPadding: Layout.Container.verticalPadding,
            horizontalPadding: Layout.Container.horizontalPadding
        )
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
            SelectorReceiveCircleButtonView(actionType: .copy, action: viewModel.copyAddressButtonDidTap)

            SelectorReceiveCircleButtonView(actionType: .share, action: viewModel.shareAddressButtonDidTap)
        }
    }
}

// MARK: - Layout

private extension SelectorReceiveAssetsDomainItemView {
    enum Layout {
        enum Container {
            static let verticalPadding: CGFloat = 14
            static let horizontalPadding: CGFloat = 12
            static let contentSpacing: CGFloat = 12
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
