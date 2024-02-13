//
//  SendFinishView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct SendFinishView: View {
    let namespace: Namespace.ID

    @ObservedObject var viewModel: SendFinishViewModel

    var body: some View {
        VStack {
            GroupedScrollView(spacing: 14) {
                if viewModel.showHeader {
                    header
                        .padding(.bottom, 24)
                }

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
                .backgroundColor(Colors.Background.action, id: SendViewNamespaceId.address.rawValue, namespace: namespace)

                GroupedSection(viewModel.amountSummaryViewData) {
                    AmountSummaryView(data: $0)
                        .setNamespace(namespace)
                        .setTitleNamespaceId(SendViewNamespaceId.amountTitle.rawValue)
                        .setIconNamespaceId(SendViewNamespaceId.tokenIcon.rawValue)
                        .setAmountCryptoNamespaceId(SendViewNamespaceId.amountCryptoText.rawValue)
                        .setAmountFiatNamespaceId(SendViewNamespaceId.amountFiatText.rawValue)
                }
                .innerContentPadding(12)
                .backgroundColor(Colors.Background.action, id: SendViewNamespaceId.amountContainer.rawValue, namespace: namespace)

                GroupedSection(viewModel.feeSummaryViewData) { data in
                    DefaultTextWithTitleRowView(data: data)
                        .setNamespace(namespace)
                        .setTitleNamespaceId(SendViewNamespaceId.feeTitle.rawValue)
                        .setTextNamespaceId(SendViewNamespaceId.feeSubtitle.rawValue)
                }
                .backgroundColor(Colors.Background.action, id: SendViewNamespaceId.feeContainer.rawValue, namespace: namespace)
            }

            if viewModel.showButtons {
                bottomButtons
                    .padding(.horizontal, 16)
            }
        }
        .background(Colors.Background.tertiary.edgesIgnoringSafeArea(.all))
        .onAppear(perform: viewModel.onAppear)
    }

    @ViewBuilder
    private var header: some View {
        VStack(spacing: 0) {
            Assets.inProgress
                .image

            Text(Localization.sentTransactionSentTitle)
                .style(Fonts.Bold.title3, color: Colors.Text.primary1)
                .padding(.top, 18)

            Text(viewModel.transactionTime)
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                .lineLimit(1)
                .padding(.top, 6)
        }
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    @ViewBuilder
    private var bottomButtons: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                MainButton(
                    title: Localization.commonExplore,
                    icon: .leading(Assets.globe),
                    style: .secondary,
                    action: viewModel.explore
                )
                MainButton(
                    title: Localization.commonShare,
                    icon: .leading(Assets.share),
                    style: .secondary,
                    action: viewModel.share
                )
            }

            MainButton(
                title: Localization.commonClose,
                action: viewModel.close
            )
        }
        .transition(.opacity)
    }
}

struct SendFinishView_Previews: PreviewProvider {
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
        cryptoIconURL: nil,
        cryptoCurrencyCode: "USDT",
        fiatIconURL: nil,
        fiatCurrencyCode: "USD",
        amountFractionDigits: 6,
        feeFractionDigits: 6,
        feeAmountType: .coin
    )

    static var previews: some View {
        SendFinishView(namespace: namespace, viewModel: SendFinishViewModel(input: SendFinishViewModelInputMock(), walletInfo: walletInfo)!)
    }
}
