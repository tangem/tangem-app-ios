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
    let namespace: Namespace

    var body: some View {
        GroupedScrollView(spacing: 20) {
            GroupedSection(viewModel.destinationAddressViewModel) {
                SendNewDestinationAddressView(viewModel: $0, namespace: namespace)
            } footer: {
                DefaultFooterView(viewModel.addressDescription)
                    .transition(transitionService.destinationAuxiliaryViewTransition)
            }
            .innerContentPadding(12)
            .backgroundColor(Colors.Background.action)
            .geometryEffect(.init(id: namespace.names.addressBackground, namespace: namespace.id))
            .animation(SendTransitionService.Constants.newAnimation, value: viewModel.addressTextViewHeightModel.height)

            GroupedSection(viewModel.additionalFieldViewModel) {
                SendNewDestinationAdditionalFieldView(viewModel: $0, namespace: namespace)
            } footer: {
                DefaultFooterView(viewModel.additionalFieldDescription)
                    .transition(transitionService.destinationAuxiliaryViewTransition)
            }
            .innerContentPadding(12)
            .backgroundColor(Colors.Background.action)
            .geometryEffect(.init(
                id: namespace.names.addressAdditionalFieldBackground,
                namespace: namespace.id
            ))
            .transition(transitionService.destinationAuxiliaryViewTransition)

            if let suggestedDestinationViewModel = viewModel.suggestedDestinationViewModel {
                if viewModel.shouldShowSuggestedDestination {
                    SendSuggestedDestinationView(viewModel: suggestedDestinationViewModel)
                        .transition(.opacity.animation(SendTransitionService.Constants.newAnimation))
                }
            }
        }
        .transition(transitionService.transitionToDestinationStep(isEditMode: viewModel.isEditMode))
        .onAppear(perform: viewModel.onAppear)
    }
}

extension SendNewDestinationView {
    typealias Namespace = SendDestinationView.Namespace
}
