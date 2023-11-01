//
//  SendFeeView.swift
//  Send
//
//  Created by [REDACTED_AUTHOR]
//

import SwiftUI

struct SendFeeView: View {
    let namespace: Namespace.ID
    let viewModel: SendFeeViewModel

    var body: some View {
        VStack {
            TextField("fee", text: viewModel.fee)
                .padding()
                .border(Color.blue, width: 5)
                .matchedGeometryEffect(id: "fee", in: namespace)

            Spacer()
        }
        .padding(.horizontal)
    }
}

private enum PreviewData {
    @Namespace static var namespace
}

#Preview {
    SendFeeView(namespace: PreviewData.namespace, viewModel: SendFeeViewModel(input: SendFeeViewModelInputMock()))
}
