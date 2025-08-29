//
//  SendNewDestinationView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

struct SendNewDestinationView: View {
    @ObservedObject var viewModel: SendNewDestinationViewModel
    let transitionService: SendTransitionService

    var body: some View {
        GroupedScrollView(spacing: 20) {
            GroupedSection(viewModel.destinationAddressSectionType) { type in
                switch type {
                case .destinationAddress(let viewModel):
                    SendNewDestinationAddressView(viewModel: viewModel)
                case .destinationResolvedAddress(let resolved):
                    Text(resolved)
                        .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            } footer: {
                DefaultFooterView(Localization.sendRecipientAddressFooter(viewModel.networkName))
            }
            .interItemSpacing(12)
            .innerContentPadding(12)
            .backgroundColor(Colors.Background.action)

            GroupedSection(viewModel.additionalFieldViewModel) {
                SendNewDestinationAdditionalFieldView(viewModel: $0)
            } footer: {
                DefaultFooterView(Localization.sendRecipientMemoFooter)
            }
            .innerContentPadding(12)
            .backgroundColor(Colors.Background.action)

            if let suggestedDestinationViewModel = viewModel.suggestedDestinationViewModel {
                if viewModel.shouldShowSuggestedDestination {
                    SendSuggestedDestinationView(viewModel: suggestedDestinationViewModel)
                        .transition(transitionService.newDestinationSuggestedViewTransition)
                }
            }
        }
        .transition(transitionService.transitionToNewDestinationStep())
        .onAppear(perform: viewModel.onAppear)
    }
}

extension SendNewDestinationView {
    typealias Namespace = SendDestinationView.Namespace
}
