//
//  SendSummaryView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct SendSummaryView: View {
    let height = 150.0
    let namespace: Namespace.ID

    @ObservedObject var viewModel: SendSummaryViewModel

    var body: some View {
        VStack {
            GroupedScrollView {
                GroupedSection(SendWalletSummaryViewModel(walletName: "Family Wallet", totalBalance: "2 130,88 USDT (2 129,92 $)")) { viewModel in
                    SendWalletSummaryView(viewModel: viewModel)
                }
                .backgroundColor(Colors.Button.disabled)

                Button {
                    viewModel.didTapSummary(for: .amount)
                } label: {
                    GroupedSection(viewModel.amountSummaryViewData) {
                        AmountSummaryView(data: $0)
                    }
                    .interSectionPadding(12)
                    .backgroundColor(Colors.Background.action)
                }
                .matchedGeometryEffect(id: "amount", in: namespace)
                .transition(.asymmetric(insertion: .move(edge: .leading), removal: .opacity.combined(with: .scale)))
                .disabled(!viewModel.canEditAmount)

                Button {
                    viewModel.didTapSummary(for: .destination)
                } label: {
                    GroupedSection(
                        [
                            SendDestinationSummaryViewType.address(address: "0x391316d97a07027a0702c8A002c8A0C25d8470"),
                            SendDestinationSummaryViewType.additionalField(type: .memo, value: "123456789"),
                        ]
                    ) { type in
                        switch type {
                        case .address(let address):
                            SendDestinationAddressSummaryView(address: address)
                        case .additionalField(let type, let value):
                            if let name = type.name {
                                DefaultTextWithTitleRowView(data: .init(title: name, text: value))
                            }
                        }
                    }
                    .backgroundColor(Colors.Background.action)
                }
                .matchedGeometryEffect(id: "dest", in: namespace)
                .transition(.asymmetric(insertion: .move(edge: .leading), removal: .opacity.combined(with: .scale).combined(with: .offset(y: -height - 20))))
                .disabled(!viewModel.canEditDestination)

                GroupedSection(DefaultTextWithTitleRowViewData(title: "Network fee", text: "0.159817 MATIC (0.22 $)")) { data in
                    DefaultTextWithTitleRowView(data: data)
                }
                .backgroundColor(Colors.Background.action)
                .matchedGeometryEffect(id: "fee", in: namespace)
                .transition(.asymmetric(insertion: .move(edge: .leading), removal: .opacity.combined(with: .scale).combined(with: .offset(y: -height - 20))))
            }

            sendButton
                .padding(.horizontal, 16)
        }
        .background(Colors.Background.tertiary.edgesIgnoringSafeArea(.all))
    }

    @ViewBuilder
    private var destinationSummary: some View {
        Button {
            viewModel.didTapSummary(for: .destination)
        } label: {
            Color.clear
                .frame(maxHeight: height)
                .border(Color.purple, width: 5)
                .overlay(
                    VStack(alignment: .leading) {
                        HStack {
                            Text(viewModel.destinationText)
                                .lineLimit(1)
                                .foregroundColor(.black)
                            Spacer()
                        }
                    }
                    .padding()
                )
                .matchedGeometryEffect(id: "dest", in: namespace)
        }
        .transition(.asymmetric(insertion: .move(edge: .leading), removal: .opacity.combined(with: .scale).combined(with: .offset(y: -height - 20))))
        .disabled(!viewModel.canEditDestination)
    }

    @ViewBuilder
    private var feeSummary: some View {
        Button {
            viewModel.didTapSummary(for: .fee)
        } label: {
            Color.clear
                .frame(maxHeight: height)
                .border(Color.blue, width: 5)
                .overlay(
                    VStack(alignment: .leading) {
                        HStack {
                            Text(viewModel.feeText)
                                .foregroundColor(.black)
                            Spacer()
                        }
                    }
                    .padding()
                )
                .transition(.identity)
                .matchedGeometryEffect(id: "fee", in: namespace)
        }
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

    static var previews: some View {
        SendSummaryView(namespace: namespace, viewModel: SendSummaryViewModel(input: SendSummaryViewModelInputMock()))
    }
}
