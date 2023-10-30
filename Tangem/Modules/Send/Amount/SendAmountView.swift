//
//  SendAmountView.swift
//  Send
//
//  Created by [REDACTED_AUTHOR]
//

import SwiftUI

struct Lorem: View {
    
    let z = [
        "But I must explain to you how all this mistaken idea of denouncing pleasure and praising pain was born and I will give you a complete account of the system, and expound the actual teachings of",
        "the great explorer of the truth, the master-builder of human happiness. No one rejects,",
        "dislikes, or avoids pleasure itself, because it is pleasure, but because those who do not know how to pursue pleasure rationally encounter ",
        "consequences that are extremely painful. Nor again is there anyone who loves or pursues or desires to obtain pain of itself, because it is pain, but because occasionally circumstances occur in which toil and pain can procure him some great pleasure?",
    
    ]
    var body: some View {
        VStack {
            Text(z.shuffled().joined(separator: "\n\n"))
        }
    }
}

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
            .border(Color.green, width: 5)
            .matchedGeometryEffect(id: "amount", in: namespace)
            
            Lorem()

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
