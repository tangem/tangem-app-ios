//
//  SendView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct SendView: View {
    @Namespace var namespace

    @ObservedObject var viewModel: SendViewModel

    var body: some View {
        VStack {
            title

            currentPage

            if viewModel.showNavigationButtons {
                navigationButtons
            }

            Color.clear.frame(height: 1)
        }
        .animation(.easeOut(duration: 0.3), value: viewModel.step)
        .alert(item: $viewModel.alert) { $0.alert }
    }

    @ViewBuilder
    private var title: some View {
        Text(viewModel.title)
            .font(.title2)
            .animation(nil)
    }

    @ViewBuilder
    private var currentPage: some View {
        switch viewModel.step {
        case .amount:
            SendAmountView(namespace: namespace, viewModel: viewModel.sendAmountViewModel)
        case .destination:
            SendDestinationView(namespace: namespace, viewModel: viewModel.sendDestinationViewModel)
        case .fee:
            SendFeeView(namespace: namespace, viewModel: viewModel.sendFeeViewModel)
        case .summary:
            SendSummaryView(namespace: namespace, viewModel: viewModel.sendSummaryViewModel)
        }
    }

    @ViewBuilder
    private var navigationButtons: some View {
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
                        .background(viewModel.currentStepInvalid ? Color.gray : Color.black)
                        .cornerRadius(10)
                }
                .disabled(viewModel.currentStepInvalid)
            }
        }
        .padding(.horizontal)
    }
}

struct SendView_Preview: PreviewProvider {
    static let viewModel = SendViewModel(
        walletModel: WalletModelsManagerMock().walletModels.first!,
        transactionSigner: TransactionSignerMock(),
        sendType: .send,
        coordinator: SendRoutableMock()
    )

    static var previews: some View {
        SendView(viewModel: viewModel)
    }
}
