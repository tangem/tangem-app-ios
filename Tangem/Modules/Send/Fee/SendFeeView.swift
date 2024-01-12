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

    @ObservedObject var viewModel: SendFeeViewModel

    var body: some View {
        GroupedScrollView {
            GroupedSection(viewModel.feeRowViewModels) {
                FeeRowView(viewModel: $0)
            } footer: {
                DefaultFooterView(Localization.commonFeeSelectorFooter)
            }
            .verticalPadding(0)
            .separatorStyle(.minimum)
            .backgroundColor(Colors.Background.action)

            if viewModel.showCustomFeeFields {
                SendCustomFeeInputField(
                    viewModel: SendCustomFeeInputFieldModel(
                        title: "Fee up to",
                        amount: .constant(.internal(1234)),
                        fractionDigits: 0,
                        amountAlternativePublisher: .just(output: "0.41 $"),
                        footer: "Maximum commission amount"
                    )
                )

                SendCustomFeeInputField(
                    viewModel: SendCustomFeeInputFieldModel(
                        title: "Gas price",
                        amount: .constant(.internal(1234)),
                        fractionDigits: 0,
                        amountAlternativePublisher: .just(output: nil),
                        footer: "Gas Price impacts transaction speed; too low, it may not process"
                    )
                )

                SendCustomFeeInputField(
                    viewModel: SendCustomFeeInputFieldModel(
                        title: "Gas limit",
                        amount: .constant(.internal(1234)),
                        fractionDigits: 0,
                        amountAlternativePublisher: .just(output: nil),
                        footer: "Gas Limit is auto-calculated; raise it during network congestion"
                    )
                )
            }
        }
        .background(Colors.Background.tertiary.edgesIgnoringSafeArea(.all))
    }
}

struct SendFeeView_Previews: PreviewProvider {
    @Namespace static var namespace

    static var previews: some View {
        SendFeeView(namespace: namespace, viewModel: SendFeeViewModel(input: SendFeeViewModelInputMock()))
    }
}
