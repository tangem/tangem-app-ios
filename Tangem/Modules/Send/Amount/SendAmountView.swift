//
//  SendAmountView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct SendAmountView: View {
    let namespace: Namespace.ID

    @ObservedObject var viewModel: SendAmountViewModel

    var body: some View {
        VStack {
            TextField("0", text: viewModel.amountText)
                .padding()
                .border(Color.green, width: 5)
                .matchedGeometryEffect(id: "amount", in: namespace)

            Button(action: viewModel.didTapMaxAmount) {
                Text("Max amount")
            }

            Text(viewModel.amountError ?? " ")
                .foregroundColor(.red)

            Spacer()
        }
        .padding(.horizontal)
    }
}

struct SendAmountView_Previews: PreviewProvider {
    @Namespace static var namespace

    static var previews: some View {
        SendAmountView(namespace: namespace, viewModel: SendAmountViewModel(input: SendAmountViewModelInputMock()))
    }
}
