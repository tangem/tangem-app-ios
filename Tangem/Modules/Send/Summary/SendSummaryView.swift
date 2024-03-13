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
        VStack {
            GroupedScrollView(spacing: 14) {
                GroupedSection(viewModel.walletSummaryViewModel) { viewModel in
                    SendWalletSummaryView(viewModel: viewModel)
                }
                .backgroundColor(Colors.Button.disabled)

                GroupedSection(viewModel.destinationViewTypes) { type in
                    switch type {
                    case .address(let address):
                        SendDestinationAddressSummaryView(address: address)
                            .setNamespace(namespace)
                            .visible(viewModel.showSectionContent)
                    case .additionalField(let type, let value):
                        if let name = type.name {
                            DefaultTextWithTitleRowView(data: .init(title: name, text: value))
                                .visible(viewModel.showSectionContent)
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
                        .visible(viewModel.showSectionContent)
                }
                .innerContentPadding(12)
                .backgroundColor(viewModel.amountBackground, id: SendViewNamespaceId.amountContainer.rawValue, namespace: namespace)
                .contentShape(Rectangle())
                .allowsHitTesting(viewModel.canEditAmount)
                .onTapGesture {
                    viewModel.didTapSummary(for: .amount)
                }

                GroupedSection(viewModel.feeSummaryViewData) { data in
                    feeSectionContent(data: data)
                        .visible(viewModel.showSectionContent)
                }
                .backgroundColor(Colors.Background.action, id: SendViewNamespaceId.feeContainer.rawValue, namespace: namespace)
                .contentShape(Rectangle())
                .onTapGesture {
                    viewModel.didTapSummary(for: .fee)
                }

                ForEach(viewModel.notificationInputs) { input in
                    NotificationView(input: input)
                        .transition(SendView.Constants.auxiliaryViewTransition)
                }
            }

            sendButton
                .padding(.horizontal, 16)
                .padding(.bottom, 6)
        }
        .background(Colors.Background.tertiary.edgesIgnoringSafeArea(.all))
        .alert(item: $viewModel.alert) { $0.alert }
        .onAppear(perform: viewModel.onAppear)
        .onDisappear(perform: viewModel.onDisappear)
        .onAppear(perform: viewModel.onSectionContentAppear)
        .onDisappear(perform: viewModel.onSectionContentDisappear)
        .interactiveDismissDisabled(viewModel.isSending)
    }

    private func amountSectionContent(data: AmountSummaryViewData) -> some View {
        AmountSummaryView(data: data)
            .setNamespace(namespace)
            .setTitleNamespaceId(SendViewNamespaceId.amountTitle.rawValue)
            .setIconNamespaceId(SendViewNamespaceId.tokenIcon.rawValue)
            .setAmountCryptoNamespaceId(SendViewNamespaceId.amountCryptoText.rawValue)
            .setAmountFiatNamespaceId(SendViewNamespaceId.amountFiatText.rawValue)
    }

    private func feeSectionContent(data: DefaultTextWithTitleRowViewData) -> some View {
        DefaultTextWithTitleRowView(data: data)
            .setNamespace(namespace)
            .setTitleNamespaceId(SendViewNamespaceId.feeTitle.rawValue)
            .setTextNamespaceId(SendViewNamespaceId.feeSubtitle.rawValue)
            // To maintain cell animation from Summary to Fee screen
            .overlay(feeIcon.opacity(0), alignment: .topLeading)
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

    @ViewBuilder
    private var feeIcon: some View {
        if let feeOptionIcon = viewModel.feeOptionIcon {
            feeOptionIcon
                .matchedGeometryEffect(id: SendViewNamespaceId.feeIcon.rawValue, in: namespace)
        }
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

    static var previews: some View {
        SendSummaryView(namespace: namespace, viewModel: SendSummaryViewModel(input: SendSummaryViewModelInputMock(), notificationManager: FakeSendNotificationManager(), walletInfo: walletInfo))
    }
}
