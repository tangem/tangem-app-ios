//
//  SendAmountView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct SendAmountView: View {
    @ObservedObject var viewModel: SendAmountViewModel
    let namespace: Namespace.ID

    var body: some View {
        VStack(spacing: 14) {
            amountSectionContent

            if !viewModel.animatingAuxiliaryViewsOnAppear {
                HStack {
                    SendCurrencyPicker(
                        cryptoIconURL: viewModel.cryptoIconURL,
                        cryptoCurrencyCode: viewModel.cryptoCurrencyCode,
                        fiatIconURL: viewModel.fiatIconURL,
                        fiatCurrencyCode: viewModel.fiatCurrencyCode,
                        disabled: viewModel.currencyPickerDisabled,
                        useFiatCalculation: $viewModel.useFiatCalculation
                    )

                    MainButton(title: Localization.sendMaxAmount, style: .secondary, action: viewModel.didTapMaxAmount)
                        .frame(width: 108)
                }
                .transition(SendView.Constants.auxiliaryViewTransition(for: .amount))
            }
        }
        .onAppear(perform: viewModel.onAppear)
        .onAppear(perform: viewModel.onAuxiliaryViewAppear)
        .onDisappear(perform: viewModel.onAuxiliaryViewDisappear)
    }

    private var amountSectionContent: some View {
        VStack(spacing: 34) {
            if !viewModel.animatingAuxiliaryViewsOnAppear {
                walletInfoView
                    // Because the top padding have to be is 16 to the white background
                    // But the bottom padding have to be is 12
                    .padding(.top, 4)
                    .transition(.offset(y: -100).combined(with: .opacity))
            }

            amountContent
        }
        .frame(maxWidth: .infinity)
        .defaultRoundedBackground(
            with: Colors.Background.action,
            geometryEffect: .init(id: SendViewNamespaceId.amountContainer.rawValue, namespace: namespace)
        )
    }

    private var walletInfoView: some View {
        VStack(spacing: 4) {
            Text(viewModel.walletName)
                .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
                .lineLimit(1)
                .matchedGeometryEffect(id: SendViewNamespaceId.walletName.rawValue, in: namespace)

            SensitiveText(viewModel.balance)
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                .lineLimit(1)
                .matchedGeometryEffect(id: SendViewNamespaceId.walletBalance.rawValue, in: namespace)
        }
    }

    private var amountContent: some View {
        VStack(spacing: 18) {
            TokenIcon(tokenIconInfo: viewModel.tokenIconInfo, size: CGSize(width: 36, height: 36))
                .matchedGeometryEffect(id: SendViewNamespaceId.tokenIcon.rawValue, in: namespace)

            VStack(spacing: 6) {
                SendDecimalNumberTextField(viewModel: viewModel.decimalNumberTextFieldViewModel)
                    // A small delay must be introduced to fix a glitch in a transition animation when changing screens
                    .initialFocusBehavior(.delayedFocus(duration: 2 * SendView.Constants.animationDuration))
                    .alignment(.center)
                    .prefixSuffixOptions(viewModel.currentFieldOptions)
                    .matchedGeometryEffect(id: SendViewNamespaceId.amountCryptoText.rawValue, in: namespace)

                // Keep empty text so that the view maintains its place in the layout
                Text(viewModel.amountAlternative ?? " ")
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                    .lineLimit(1)
                    .matchedGeometryEffect(id: SendViewNamespaceId.amountFiatText.rawValue, in: namespace)

                Text(viewModel.error ?? " ")
                    .style(Fonts.Regular.caption1, color: Colors.Text.warning)
                    .lineLimit(1)
            }
        }
    }
}

struct SendAmountView_Previews: PreviewProvider {
    @Namespace static var namespace

    static let tokenIconInfo = TokenIconInfo(
        name: "Tether",
        blockchainIconName: "ethereum.fill",
        imageURL: IconURLBuilder().tokenIconURL(id: "tether"),
        isCustom: false,
        customTokenColor: nil
    )

    static let walletInfo = SendWalletInfo(
        walletName: "Family Wallet",
        balanceValue: 2130.88,
        balance: "2 130,88 USDT (2 129,92 $)",
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
        feeAmountType: .coin,
        canUseFiatCalculation: true
    )

    static let viewModel = SendAmountViewModel(
        input: SendAmountViewModelInputMock(),
        fiatCryptoAdapter: SendFiatCryptoAdapterMock(),
        walletInfo: walletInfo
    )

    static var previews: some View {
        SendAmountView(viewModel: viewModel, namespace: namespace)
    }
}
