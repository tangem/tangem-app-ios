//
//  SendSummaryView.swift
//  Send
//
//  Created by [REDACTED_AUTHOR]
//

import SwiftUI

struct SendSummaryView: View {
    let height = 150.0
    let namespace: Namespace.ID
    let sendViewModel: SendViewModel

    var body: some View {
        VStack(spacing: 20) {
            Button(action: {
                sendViewModel.didTapSummary(step: .amount)
            }, label: {
                Color.clear
                    .frame(maxHeight: height)
                    .border(Color.green, width: 5)
                    .overlay(
                        VStack {
                            HStack {
                                Text(sendViewModel.sendAmountInput.amountText)
                                    .foregroundStyle(.black)
                                Spacer()
                            }
                        }
                        .padding()
                    )
                    .matchedGeometryEffect(id: "amount", in: namespace)
            })

            Button(action: {
                sendViewModel.didTapSummary(step: .destination)
            }, label: {
                Color.clear
                    .frame(maxHeight: height)
                    .border(Color.purple, width: 5)
                    .overlay(
                        VStack(alignment: .leading) {
                            HStack {
                                Text(sendViewModel.sendDestinationInput.destinationText)
                                    .lineLimit(1)
                                    .foregroundStyle(.black)
                                Spacer()
                            }
                        }
                        .padding()
                    )
                    .matchedGeometryEffect(id: "dest", in: namespace)

            })

            Button(action: {
                sendViewModel.didTapSummary(step: .fee)
            }, label: {
                Color.clear
                    .frame(maxHeight: height)
                    .border(Color.blue, width: 5)
                    .overlay(
                        VStack(alignment: .leading) {
                            HStack {
                                Text(sendViewModel.sendFeeInput.feeText)
                                    .foregroundStyle(.black)
                                Spacer()
                            }
                        }
                        .padding()
                    )
                    .matchedGeometryEffect(id: "fee", in: namespace)
            })

            Spacer()

            Button(action: {}) {
                Text("Send")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.black)
                    .cornerRadius(10)
            }
            .animation(nil, value: UUID())
            .transaction { transaction in
                transaction.animation = nil
                transaction.disablesAnimations = true
            }
        }
        .padding(.horizontal)
    }
}

private enum S {
    @Namespace static var namespace // <- This
}

#Preview {
    SendSummaryView(namespace: S.namespace, sendViewModel: SendViewModel(coordinator: MockSendRoutable()))
}
