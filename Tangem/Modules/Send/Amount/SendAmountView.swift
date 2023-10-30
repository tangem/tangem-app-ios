//
//  SendAmountView.swift
//  Send
//
//  Created by [REDACTED_AUTHOR]
//

import SwiftUI

struct SendAmountView: View {
    let namespace: Namespace.ID

    let viewModel: SendAmountViewModel

    var body: some View {
        VStack {
            VStack {
                TextField("0.00 USDT", text: viewModel.amountText)
                    .keyboardType(.decimalPad)
            }
            .padding()
            .border(Color.red, width: 5)
            .matchedGeometryEffect(id: "amount", in: namespace)

            Spacer()

            Button(action: {}, label: {
                Text("set")
            })
        }
        .padding()
    }
}

// #Preview {
//    SendAmountView(viewModel: SendAmountViewModel(amountText: .constant("100 USDT")))
// }
