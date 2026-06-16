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
            .backgroundColor(Colors.Background.action)

            GroupedSection(viewModel.additionalFieldViewModel) {
                SendDestinationAdditionalFieldView(viewModel: $0)
            } footer: {
                DefaultFooterView(Localization.sendRecipientMemoFooter)
            }
            .innerContentPadding(12)
            .backgroundColor(Colors.Background.action)

            GroupedSection(viewModel.addressNetworksType) { networks in
                TangemRow(title: Localization.commonNetwork)
                    .verticalAlignment(.center)
                    .end { makeNetworksValue(networks: networks) }
                    .if(networks.isEditable) { $0.onTap(viewModel.userDidRequestNetworksChange) }
            }
            .backgroundColor(DesignSystem.Tokens.Theme.Bg.secondary)
            .horizontalPadding(0)
        }
        .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
        .navigationTitle(Text(Localization.addressBookAddAddress))
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) { bottomButton }
    }

    private func makeNetworksValue(networks: AddressBookAddAddressViewModel.AddressNetworksType) -> some View {
        HStack(spacing: 4) {
            let title = switch networks {
            case .idle: Localization.addressBookSelectNetwork
            case .resolved(let networks): networks.map { $0.currencySymbol }.joined(separator: ", ")
            }

            Text(title)
                .style(DesignSystem.Tokens.Font.Body.medium, color: DesignSystem.Tokens.Theme.Text.secondary)
                .lineLimit(1)

            if networks.isEditable {
                Assets.Glyphs.selectIcon.image
                    .renderingMode(.template)
                    .foregroundStyle(DesignSystem.Tokens.Theme.Icon.secondary)
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
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}
