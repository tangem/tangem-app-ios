//
//  RedesignedSelectorReceiveAssetsDomainItemView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemUI
import TangemUIUtils
import TangemAssets
import TangemLocalization

struct RedesignedSelectorReceiveAssetsDomainItemView: View {
    @ObservedObject private(set) var viewModel: SelectorReceiveAssetsDomainItemViewModel

    var body: some View {
        HStack(spacing: 12) {
            addressIconView(with: viewModel.address)

            addressContentView(value: viewModel.address)

            Spacer(minLength: .zero)

            buttonView
        }
        .padding(16)
        .background(DesignSystem.Color.bgOpaquePrimary)
        .cornerRadiusContinuous(24)
    }

    // MARK: - Private Implementation

    private func addressIconView(with address: String) -> some View {
        AddressIconView(viewModel: AddressIconViewModel(address: address))
            .frame(size: CGSize(bothDimensions: 36))
    }

    private func addressContentView(value: String) -> some View {
        Text(value)
            .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
            .lineLimit(1)
    }

    private var buttonView: some View {
        HStack(spacing: 8) {
            TangemButtonV2(
                icon: DesignSystem.Icons.Copy.regular20,
                accessibilityLabel: Localization.commonCopy,
                action: viewModel.copyAddressButtonDidTap
            )
            .size(.x9)
            .styleType(.secondary)

            TangemButtonV2(
                icon: DesignSystem.Icons.ShareIos.regular20,
                accessibilityLabel: Localization.commonShare,
                action: viewModel.shareAddressButtonDidTap
            )
            .size(.x9)
            .styleType(.secondary)
        }
    }
}
