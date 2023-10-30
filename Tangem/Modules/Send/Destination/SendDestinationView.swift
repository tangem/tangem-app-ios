//
//  SendDestinationView.swift
//  Send
//
//  Created by [REDACTED_AUTHOR]
//

import SwiftUI

struct SendDestinationView: View {
    let namespace: Namespace.ID
    let viewModel: SendDestinationViewModel

    var body: some View {
        VStack {
            VStack {
                TextField("Enter addr3ess", text: viewModel.destination)
                    .keyboardType(.decimalPad)
            }
            .padding()
            .border(Color.purple, width: 5)
            .matchedGeometryEffect(id: "dest", in: namespace)

            Spacer()

            Button(action: {}, label: {
                Text("set")
            })
        }
        .padding()
    }
}

// #Preview {
//    SendDestinationView()
// }
