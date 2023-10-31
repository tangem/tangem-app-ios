//
//  SendView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct SendView: View {
    @ObservedObject private var viewModel: SendViewModel
    @Namespace var namespace

    init(viewModel: SendViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            Text(viewModel.title)
                .font(.title2)
                .animation(nil)

            currentPage()

            if viewModel.showNavigationButtons {
                HStack {
                    if viewModel.showBackButton {
                        Button(action: viewModel.back, label: {
                            Text("Back")
                                .padding()
                                .foregroundColor(.white)
                                .background(Color.black)
                                .cornerRadius(10)
                        })
                    }

                    if viewModel.showNextButton {
                        Button(action: viewModel.next) {
                            Text("Next")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .foregroundColor(.white)
                                .background(viewModel.currentPageInvalid ? Color.gray : Color.black)
                                .cornerRadius(10)
                        }
                        .disabled(viewModel.currentPageInvalid)
                    }
                }
                .animation(nil, value: UUID())
                .transaction { transaction in
                    transaction.animation = nil
                    transaction.disablesAnimations = true
                }
                .padding(.horizontal)
            }

            Color.clear.frame(height: 1)
        }
    }

    @ViewBuilder
    func currentPage() -> some View {
        switch viewModel.step {
        case .amount:
            SendAmountView(namespace: namespace, viewModel: SendAmountViewModel(input: viewModel.sendAmountInput, validator: viewModel.sendAmountValidator))
        case .destination:
            SendDestinationView(namespace: namespace, viewModel: SendDestinationViewModel(input: viewModel.sendDestinationInput, validator: viewModel.sendDestinationValidator))
        case .fee:
            SendFeeView(namespace: namespace, viewModel: SendFeeViewModel(input: viewModel.sendFeeInput))
        case .summary:
            SendSummaryView(namespace: namespace, viewModel: SendSummaryViewModel(input: viewModel.sendSummaryInput, router: viewModel))
        }
    }
}

class MockSendRoutable: SendRoutable {
    init() {}
}

struct SendView_Preview: PreviewProvider {
    static let viewModel = SendViewModel(coordinator: MockSendRoutable())

    static var previews: some View {
        SendView(viewModel: viewModel)
    }
}
