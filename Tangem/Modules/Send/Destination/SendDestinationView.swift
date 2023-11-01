//
//  SendDestinationView.swift
//  Send
//
//  Created by [REDACTED_AUTHOR]
//

import SwiftUI

struct SendDestinationView: View {
    let namespace: Namespace.ID
    @ObservedObject var viewModel: SendDestinationViewModel

    var body: some View {
        VStack {
            VStack {
                TextField("Enter address", text: viewModel.destination)
            }
            .padding()
            .border(Color.purple, width: 5)
            .matchedGeometryEffect(id: "dest", in: namespace)

            Text(viewModel.destinationErrorText ?? " ")
                .foregroundColor(.red)

            VStack {
                TextField("Enter memo", text: viewModel.additionalField)
            }
            .padding()
            .border(Color.purple, width: 5)

            Text(viewModel.destinationAdditionalFieldErrorText ?? " ")
                .foregroundColor(.red)

            Spacer()
        }
        .padding(.horizontal)
    }
}

private enum PreviewData {
    @Namespace static var namespace
}

#Preview {
    SendDestinationView(namespace: PreviewData.namespace, viewModel: SendDestinationViewModel(input: SendDestinationViewModelInputMock()))
}
