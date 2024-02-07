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

    var body: some View {
        GroupedScrollView(spacing: 20) {
            if let addressViewModel = viewModel.addressViewModel {
                SendDestinationTextView(viewModel: addressViewModel)
                    .setNamespace(namespace)
                    .setTitleNamespaceId(SendViewNamespaceId.addressTitle.rawValue)
                    .setIconNamespaceId(SendViewNamespaceId.addressIcon.rawValue)
                    .setTextNamespaceId(SendViewNamespaceId.addressText.rawValue)
                    .setClearButtonNamespaceId(SendViewNamespaceId.addressClearButton.rawValue)
            }

            if let additionalFieldViewModel = viewModel.additionalFieldViewModel {
                SendDestinationTextView(viewModel: additionalFieldViewModel)
            }

            if let suggestedDestinationViewModel = viewModel.suggestedDestinationViewModel {
                SendSuggestedDestinationView(viewModel: suggestedDestinationViewModel)
            }
        }
        .background(Colors.Background.tertiary.edgesIgnoringSafeArea(.all))
    }
}

struct SendDestinationView_Previews: PreviewProvider {
    @Namespace static var namespace

    static var previews: some View {
        SendDestinationView(namespace: namespace, viewModel: SendDestinationViewModel(input: SendDestinationViewModelInputMock()))
    }
}
