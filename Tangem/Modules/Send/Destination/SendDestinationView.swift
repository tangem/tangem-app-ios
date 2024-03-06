//
//  SendDestinationView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct SendDestinationView: View {
    let namespace: Namespace.ID
    @ObservedObject var viewModel: SendDestinationViewModel

    let bottomSpacing: CGFloat

    var body: some View {
        GroupedScrollView(spacing: 20) {
            if let addressViewModel = viewModel.addressViewModel {
                SendDestinationTextView(viewModel: addressViewModel)
                    .setNamespace(namespace)
                    .setContainerNamespaceId(SendViewNamespaceId.addressContainer.rawValue)
                    .setTitleNamespaceId(SendViewNamespaceId.addressTitle.rawValue)
                    .setIconNamespaceId(SendViewNamespaceId.addressIcon.rawValue)
                    .setTextNamespaceId(SendViewNamespaceId.addressText.rawValue)
                    .setClearButtonNamespaceId(SendViewNamespaceId.addressClearButton.rawValue)
            }

            if let additionalFieldViewModel = viewModel.additionalFieldViewModel {
                SendDestinationTextView(viewModel: additionalFieldViewModel)
            }

            if let suggestedDestinationViewModel = viewModel.suggestedDestinationViewModel, viewModel.showSuggestedDestinations {
                SendSuggestedDestinationView(viewModel: suggestedDestinationViewModel)
                    .transition(.opacity)
            }

            Spacer(minLength: bottomSpacing)
        }
        .background(Colors.Background.tertiary.edgesIgnoringSafeArea(.all))
        .onAppear(perform: viewModel.onAuxiliaryViewAppear)
        .onDisappear(perform: viewModel.onAuxiliaryViewDisappear)
    }
}

struct SendDestinationView_Previews: PreviewProvider {
    @Namespace static var namespace

    static var previews: some View {
        SendDestinationView(namespace: namespace, viewModel: SendDestinationViewModel(input: SendDestinationViewModelInputMock()), bottomSpacing: 150)
    }
}
