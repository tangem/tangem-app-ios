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
            .separatorStyle(.minimum)
            .backgroundColor(Colors.Background.action)

            if viewModel.showCustomFeeFields,
               let customFeeModel = viewModel.customFeeModel,
               let customFeeGasPriceModel = viewModel.customFeeGasPriceModel,
               let customFeeGasLimitModel = viewModel.customFeeGasLimitModel {
                SendCustomFeeInputField(viewModel: customFeeModel)
                SendCustomFeeInputField(viewModel: customFeeGasPriceModel)
                SendCustomFeeInputField(viewModel: customFeeGasLimitModel)
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
