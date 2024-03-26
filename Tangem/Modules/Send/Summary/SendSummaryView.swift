//
//  SendSummaryView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct SendSummaryView: View {
    let namespace: Namespace.ID

    @ObservedObject var viewModel: SendSummaryViewModel

    var body: some View {
        VStack(spacing: 14) {
            GroupedScrollView(spacing: 14) {
                GroupedSection(viewModel.destinationViewTypes) { type in
                    switch type {
                    case .address(let address):
                        SendDestinationAddressSummaryView(address: address)
                            .setNamespace(namespace)
                    case .additionalField(let type, let value):
                        if let name = type.name {
                            DefaultTextWithTitleRowView(data: .init(title: name, text: value))
                        }
                    }
                }
                .backgroundColor(viewModel.destinationBackground, id: SendViewNamespaceId.addressContainer.rawValue, namespace: namespace)
                .contentShape(Rectangle())
                .allowsHitTesting(viewModel.canEditDestination)
                .onTapGesture {
                    viewModel.didTapSummary(for: .destination)
                }

                GroupedSection(viewModel.amountSummaryViewData) { data in
                    amountSectionContent(data: data)
                }
                .innerContentPadding(0)
                .backgroundColor(viewModel.amountBackground, id: SendViewNamespaceId.amountContainer.rawValue, namespace: namespace)
                .contentShape(Rectangle())
                .allowsHitTesting(viewModel.canEditAmount)
                .onTapGesture {
                    viewModel.didTapSummary(for: .amount)
                }

                VStack(spacing: 8) {
                    GroupedSection(viewModel.feeSummaryViewData) { data in
                        feeSectionContent(data: data)
                    }
                    .backgroundColor(Colors.Background.action, id: SendViewNamespaceId.feeContainer.rawValue, namespace: namespace)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.didTapSummary(for: .fee)
                    }

                    if viewModel.showHint {
                        HintView(
                            text: Localization.sendSummaryTapHint,
                            font: Fonts.Regular.footnote,
                            textColor: Colors.Text.secondary,
                            backgroundColor: Colors.Button.secondary
                        )
                    }
                }

                ForEach(viewModel.notificationInputs) { input in
                    NotificationView(input: input)
                        .transition(SendView.Constants.auxiliaryViewTransition)
                }
            }

            if let transactionDescription = viewModel.transactionDescription {
                Text(transactionDescription)
                    .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .visible(viewModel.showTransactionDescription)
            }

            sendButton
                .padding(.horizontal, 16)
                .padding(.bottom, 6)
        }
        .background(Colors.Background.tertiary.edgesIgnoringSafeArea(.all))
        .alert(item: $viewModel.alert) { $0.alert }
        .onAppear(perform: viewModel.onAppear)
        .onDisappear(perform: viewModel.onDisappear)
        .interactiveDismissDisabled(viewModel.isSending)
    }

    private func amountSectionContent(data: SendAmountSummaryViewData) -> some View {
        SendAmountSummaryView(data: data)
            .setNamespace(namespace)
            .setIconNamespaceId(SendViewNamespaceId.tokenIcon.rawValue)
            .setAmountCryptoNamespaceId(SendViewNamespaceId.amountCryptoText.rawValue)
            .setAmountFiatNamespaceId(SendViewNamespaceId.amountFiatText.rawValue)
    }

    private func feeSectionContent(data: SendFeeSummaryViewModel) -> some View {
        SendFeeSummaryView(data: data)
            .setNamespace(namespace)
            .setTitleNamespaceId(SendViewNamespaceId.feeTitle.rawValue)
            .setOptionNamespaceId(SendViewNamespaceId.feeOption.rawValue)
            .setAmountNamespaceId(SendViewNamespaceId.feeAmount.rawValue)
    }

    @ViewBuilder
    private var sendButton: some View {
        MainButton(
            title: viewModel.sendButtonText,
            icon: viewModel.sendButtonIcon,
            isDisabled: viewModel.isSending,
            action: viewModel.send
        )
    }
}

struct SendSummaryView_Previews: PreviewProvider {
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
        cryptoIconURL: nil,
        cryptoCurrencyCode: "USDT",
        fiatIconURL: nil,
        fiatCurrencyCode: "USD",
        amountFractionDigits: 6,
        feeFractionDigits: 6,
        feeAmountType: .coin
    )

    static let viewModel = SendSummaryViewModel(
        input: SendSummaryViewModelInputMock(),
        notificationManager: FakeSendNotificationManager(),
        fiatCryptoValueProvider: SendFiatCryptoValueProviderMock(),
        walletInfo: walletInfo
    )

    static var previews: some View {
        SendSummaryView(namespace: namespace, viewModel: viewModel)
    }
}
