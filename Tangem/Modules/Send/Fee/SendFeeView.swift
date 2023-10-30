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
            VStack {
                TextField("fee", text: viewModel.fee)
//                TextField("0.00 USDT", text: viewModel.amountText)
//                    .keyboardType(.decimalPad)
            }
            .padding()
            .border(Color.blue, width: 5)
            .matchedGeometryEffect(id: "fee", in: namespace)

            Lorem()
            
            Spacer()

            Button(action: {}, label: {
                Text("set")
            })
        }
        .padding(.horizontal)
    }
}

//
// #Preview {
//    SendFeeView()
// }
