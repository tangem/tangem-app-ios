//
//  AddressBookAddAddressView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

struct AddressBookAddAddressView: View {
    @ObservedObject var viewModel: AddressBookAddAddressViewModel

    var body: some View {
        GroupedScrollView(contentType: .lazy(alignment: .center, spacing: 20)) {
            GroupedSection(viewModel.destinationAddressViewModel) {
                SendDestinationAddressView(viewModel: $0)
            }
            .interItemSpacing(12)
            .innerContentPadding(12)
            .backgroundColor(DesignSystem.Color.bgSecondary)

            GroupedSection(viewModel.additionalFieldViewModel) {
                SendDestinationAdditionalFieldView(viewModel: $0)
            } footer: {
                DefaultFooterView(Localization.sendRecipientMemoFooter)
            }
            .innerContentPadding(12)
            .backgroundColor(DesignSystem.Color.bgSecondary)

            GroupedSection(viewModel.addressNetworksType) { networks in
                TangemRow(title: Localization.commonNetwork)
                    .verticalAlignment(.center)
                    .end { makeNetworksValue(networks: networks) }
                    .if(networks.isEditable) { $0.onTap(viewModel.userDidRequestNetworksChange) }
            }
            .backgroundColor(DesignSystem.Color.bgSecondary)
            .horizontalPadding(0)
        }
        .background(DesignSystem.Color.bgBase.ignoresSafeArea())
        .navigationTitle(Text(Localization.addressBookAddAddress))
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) { bottomButton }
    }

    private func makeNetworksValue(networks: AddressBookAddAddressViewModel.AddressNetworksType) -> some View {
        HStack(spacing: 4) {
            let title = switch networks {
            case .idle:
                Localization.addressBookSelectNetwork
            case .resolved(let networks):
                // [REDACTED_TODO_COMMENT]
                networks.map { $0.currencySymbol }.joined(separator: ", ")
            }

            Text(title)
                .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textSecondary)
                .lineLimit(1)

            if networks.isEditable {
                Assets.Glyphs.selectIcon.image
                    .renderingMode(.template)
                    .foregroundStyle(DesignSystem.Color.iconSecondary)
                    .frame(width: 20, height: 20)
            }
        }
    }

    private var bottomButton: some View {
        TangemButton(
            content: .text(AttributedString(Localization.addressBookAddAddress)),
            action: viewModel.userDidRequestAddAddress
        )
        .setCornerStyle(.rounded)
        .setHorizontalLayout(.infinity)
        .setSize(.x12)
        .setStyleType(.primary)
        .setButtonState(isLoading: false, isDisabled: !viewModel.isAddAddressEnabled)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}
