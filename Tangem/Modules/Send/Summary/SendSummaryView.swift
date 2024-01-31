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
            GroupedScrollView {
                GroupedSection(viewModel.walletSummaryViewModel) { viewModel in
                    SendWalletSummaryView(viewModel: viewModel)
                }
                .backgroundColor(Colors.Button.disabled)

                Button {
                    viewModel.didTapSummary(for: .destination)
                } label: {
                    GroupedSection(viewModel.destinationViewTypes) { type in
                        switch type {
                        case .address(let address):
                            SendDestinationAddressSummaryView(address: address)
                                .matchedGeometryEffect(id: SendViewNamespaceId.address, in: namespace)
                        case .additionalField(let type, let value):
                            if let name = type.name {
                                DefaultTextWithTitleRowView(data: .init(title: name, text: value))
                                    .matchedGeometryEffect(id: SendViewNamespaceId.additionalField, in: namespace)
                            }
                        }
                    }
                    .backgroundColor(Colors.Background.action)
                }
                .transition(.asymmetric(insertion: .move(edge: .leading), removal: .opacity.combined(with: .scale)))
                .disabled(!viewModel.canEditDestination)

//                Button {
//                    viewModel.didTapSummary(for: .amount)
//                } label: {
                GroupedSection(viewModel.amountSummaryViewData) {
                    AmountSummaryView(data: $0)
                        .setNamespace(namespace)
                        .setTitleNamespaceId(SendViewNamespaceId.amountTitle.rawValue)
                        .setIconNamespaceId(SendViewNamespaceId.tokenIcon.rawValue)
                        .setAmountNamespaceId(SendViewNamespaceId.amountCryptoText.rawValue)
                }
                .interSectionPadding(12)
                .backgroundColor(Colors.Background.action, id: SendViewNamespaceId.amountContainer.rawValue, namespace: namespace)
                .onTapGesture {
                    viewModel.didTapSummary(for: .amount)
                }
//                }
//                .transition(.asymmetric(insertion: .move(edge: .leading), removal: .opacity.combined(with: .scale)))
                .disabled(!viewModel.canEditAmount)

                Button {
                    viewModel.didTapSummary(for: .fee)
                } label: {
                    GroupedSection(viewModel.feeSummaryViewData) { data in
                        DefaultTextWithTitleRowView(data: data)
                    }
                    .backgroundColor(Colors.Background.action)
                }
                .matchedGeometryEffect(id: SendViewNamespaceId.fee, in: namespace)
                .transition(.asymmetric(insertion: .move(edge: .leading), removal: .opacity.combined(with: .scale)))
            }

            sendButton
                .padding(.horizontal, 16)
        }
        .background(Colors.Background.tertiary.edgesIgnoringSafeArea(.all))
    }

    @ViewBuilder
    private var sendButton: some View {
        MainButton(
            title: Localization.commonSend,
            icon: .trailing(Assets.tangemIcon),
            isLoading: viewModel.isSending,
            action: viewModel.send
        )
    }
}

struct SendSummaryView_Previews: PreviewProvider {
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
        SendSummaryView(namespace: namespace, viewModel: SendSummaryViewModel(input: SendSummaryViewModelInputMock(), walletInfo: walletInfo))
    }
}
