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

    let bottomSpacing: CGFloat

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

            GroupedSection(viewModel.subtractFromAmountModel) {
                DefaultToggleRowView(viewModel: $0)
            } footer: {
                DefaultFooterView(viewModel.subtractFromAmountFooterText)
            }
            .backgroundColor(Colors.Background.action)

            ForEach(viewModel.feeCoverageNotificationInputs) { input in
                NotificationView(input: input)
                    .transition(.notificationTransition)
            }

            Spacer(minLength: bottomSpacing)
        }
        .background(Colors.Background.tertiary.edgesIgnoringSafeArea(.all))
    }
}

struct SendFeeView_Previews: PreviewProvider {
    @Namespace static var namespace

    static let tokenIconInfo = TokenIconInfo(
        name: "Tether",
        blockchainIconName: "ethereum.fill",
        imageURL: TokenIconURLBuilder().iconURL(id: "tether"),
        isCustom: false,
        customTokenColor: nil
    )

    static let walletInfo = SendWalletInfo(
        walletName: "Wallet",
        balance: "12013",
        blockchain: .ethereum(testnet: false),
        currencyId: "tether",
        feeCurrencySymbol: "ETH",
        feeCurrencyId: "ethereum",
        isFeeApproximate: false,
        tokenIconInfo: tokenIconInfo,
        cryptoIconURL: URL(string: "https://s3.eu-central-1.amazonaws.com/tangem.api/coins/large/tether.png")!,
        cryptoCurrencyCode: "USDT",
        fiatIconURL: URL(string: "https://vectorflags.s3-us-west-2.amazonaws.com/flags/us-square-01.png")!,
        fiatCurrencyCode: "USD",
        amountFractionDigits: 6,
        feeFractionDigits: 6,
        feeAmountType: .coin
    )

    static var previews: some View {
        SendFeeView(namespace: namespace, viewModel: SendFeeViewModel(input: SendFeeViewModelInputMock(), notificationManager: FakeUserWalletNotificationManager(), walletInfo: walletInfo), bottomSpacing: 150)
    }
}
