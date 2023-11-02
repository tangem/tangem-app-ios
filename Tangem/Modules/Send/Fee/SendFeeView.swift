//
//  SendFeeView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
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

private enum SendPreviewData {
    @Namespace static var namespace
}

#Preview {
    SendFeeView(namespace: SendPreviewData.namespace, viewModel: SendFeeViewModel(input: SendFeeViewModelInputMock()))
}
