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
        GroupedScrollView {
            if let addressViewModel = viewModel.addressViewModel {
                SendDestinationTextView(viewModel: addressViewModel)
                    .matchedGeometryEffect(id: SendViewNamespaceId.address, in: namespace)
            }

            if let additionalFieldViewModel = viewModel.additionalFieldViewModel {
                SendDestinationTextView(viewModel: additionalFieldViewModel)
                    .matchedGeometryEffect(id: SendViewNamespaceId.additionalField, in: namespace)
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
