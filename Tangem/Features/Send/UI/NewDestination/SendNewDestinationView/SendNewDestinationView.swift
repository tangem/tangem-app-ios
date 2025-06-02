//
//  SendNewDestinationView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct SendNewDestinationView: View {
    @ObservedObject var viewModel: SendNewDestinationViewModel
    let transitionService: SendTransitionService

    var body: some View {
        GroupedScrollView(spacing: 20) {
            GroupedSection(viewModel.destinationAddressViewModel) {
                SendNewDestinationAddressView(viewModel: $0)
            } footer: {
                DefaultFooterView(viewModel.addressDescription)
                    .transition(transitionService.destinationAuxiliaryViewTransition)
            }
            .innerContentPadding(12)
            .backgroundColor(Colors.Background.action)
            .animation(SendTransitionService.Constants.newAnimation, value: viewModel.addressTextViewHeightModel.height)

            GroupedSection(viewModel.additionalFieldViewModel) {
                SendNewDestinationAdditionalFieldView(viewModel: $0)
            } footer: {
                DefaultFooterView(viewModel.additionalFieldDescription)
                    .transition(transitionService.destinationAuxiliaryViewTransition)
            }
            .innerContentPadding(12)
            .backgroundColor(Colors.Background.action)
            .transition(transitionService.destinationAuxiliaryViewTransition)

            if let suggestedDestinationViewModel = viewModel.suggestedDestinationViewModel {
                if viewModel.shouldShowSuggestedDestination {
                    SendSuggestedDestinationView(viewModel: suggestedDestinationViewModel)
                        .transition(.opacity.animation(SendTransitionService.Constants.newAnimation))
                }
            }
        }
        .id(viewModel.id)
        .transition(transitionService.transitionToNewDestinationStep(isEditMode: viewModel.isEditMode))
        .onAppear(perform: viewModel.onAppear)
    }
}

extension SendNewDestinationView {
    typealias Namespace = SendDestinationView.Namespace
}
