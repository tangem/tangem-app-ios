//
//  SendDestinationView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAccessibilityIdentifiers
import TangemAssets
import TangemLocalization
import TangemUI

struct SendDestinationView: View {
    @ObservedObject var viewModel: SendDestinationViewModel

    var body: some View {
        GroupedScrollView(contentType: .lazy(alignment: .center, spacing: 24)) {
            GroupedSection(viewModel.destinationAddressSectionType) { type in
                switch type {
                case .destinationAddress(let viewModel):
                    SendDestinationAddressView(viewModel: viewModel)
                case .destinationResolvedAddress(let resolved):
                    Text(resolved)
                        .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .accessibilityIdentifier(SendAccessibilityIdentifiers.addressResolvedAddress)
                }
            } footer: {
                DefaultFooterView(Localization.sendRecipientAddressFooter(viewModel.networkName))
                    .accessibilityIdentifier(SendAccessibilityIdentifiers.addressNetworkWarning)
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

            if let suggestedDestinationViewModel = viewModel.suggestedDestinationViewModel {
                if viewModel.shouldShowSuggestedDestination {
                    SendDestinationSuggestedView(viewModel: suggestedDestinationViewModel)
                        .transition(.opacity.animation(SendTransitions.animation))
                }
            }
        }
        .onAppear(perform: viewModel.onAppear)
    }
}
