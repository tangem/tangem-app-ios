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
            .interItemSpacing(0)
            .innerContentPadding(16)
            .backgroundColor(DesignSystem.Color.bgSecondary)
            .cornerRadius(24)

            GroupedSection(viewModel.additionalFieldViewModel) {
                SendDestinationAdditionalFieldView(viewModel: $0)
            } footer: {
                // [REDACTED_TODO_COMMENT]
                DefaultFooterView("Memo / Destination Tag is a code separating transactions to a shared recipient in a crypto network.\n**Caution: Missing a memo may lead to fund loss.**")
            }
            .innerContentPadding(16)
            .backgroundColor(DesignSystem.Color.bgSecondary)
            .cornerRadius(24)

            if case .resolved = viewModel.addressNetworksType {
                GroupedSection(viewModel.addressNetworksType) { networks in
                    TangemRow(title: Localization.commonNetwork)
                        .verticalAlignment(.center)
                        .end { makeNetworksValue(networks: networks) }
                        .if(networks.isEditable) { $0.onTap(viewModel.userDidRequestNetworksChange) }
                }
                .backgroundColor(DesignSystem.Color.bgSecondary)
                .cornerRadius(20)
                .horizontalPadding(0)
            }
        }
        .padding(.top, 12)
        .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
        .navigationTitle(Text(Localization.addressBookAddAddress))
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) { bottomButton }
        .toolbar {
            NavigationToolbarButton.close(placement: .topBarTrailing, action: viewModel.userDidRequestDismiss)
        }
    }

    private func makeNetworksValue(networks: AddressBookAddAddressViewModel.AddressNetworksType) -> some View {
        HStack(spacing: 4) {
            networksValueContent(networks: networks)

            if networks.isEditable {
                Assets.Glyphs.selectIcon.image
                    .renderingMode(.template)
                    .foregroundStyle(DesignSystem.Color.iconSecondary)
                    .frame(width: 20, height: 20)
            }
        }
    }

    @ViewBuilder
    private func networksValueContent(networks: AddressBookAddAddressViewModel.AddressNetworksType) -> some View {
        switch networks {
        case .idle:
            networksPlaceholder
        case .resolved(let resolved) where resolved.icons.isEmpty:
            networksPlaceholder
        case .resolved(let resolved):
            HStack(spacing: 8) {
                NetworksIconsView(icons: resolved.icons)

                if let name = resolved.name {
                    Text(name)
                        .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textSecondary)
                        .lineLimit(1)
                }
            }
        }
    }

    private var networksPlaceholder: some View {
        Text(Localization.addressBookSelectNetwork)
            .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textSecondary)
            .lineLimit(1)
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
