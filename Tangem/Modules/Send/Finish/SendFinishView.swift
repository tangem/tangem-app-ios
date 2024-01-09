//
//  SendFinishView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct SendFinishView: View {
    let height = 150.0
    let namespace: Namespace.ID

    @ObservedObject var viewModel: SendFinishViewModel

    var body: some View {
        VStack {
            GroupedScrollView {
                header
                    .padding(.bottom, 24)

                GroupedSection(viewModel.destinationViewTypes) { type in
                    switch type {
                    case .address(let address):
                        SendDestinationAddressSummaryView(address: address)
                            .matchedGeometryEffect(id: "dest", in: namespace)
                    case .additionalField(let type, let value):
                        if let name = type.name {
                            DefaultTextWithTitleRowView(data: .init(title: name, text: value))
                                .matchedGeometryEffect(id: "dest2", in: namespace)
                        }
                    }
                }
                .backgroundColor(Colors.Background.action)

                .transition(.asymmetric(insertion: .move(edge: .leading), removal: .opacity.combined(with: .scale).combined(with: .offset(y: -height - 20))))

                GroupedSection(viewModel.amountSummaryViewData) {
                    AmountSummaryView(data: $0)
                }
                .interSectionPadding(12)
                .backgroundColor(Colors.Background.action)
                .matchedGeometryEffect(id: "amount", in: namespace)
                .transition(.asymmetric(insertion: .move(edge: .leading), removal: .opacity.combined(with: .scale)))

                GroupedSection(viewModel.feeSummaryViewModel) { data in
                    DefaultTextWithTitleRowView(data: data)
                }
                .backgroundColor(Colors.Background.action)
                .matchedGeometryEffect(id: "fee", in: namespace)
                .transition(.asymmetric(insertion: .move(edge: .leading), removal: .opacity.combined(with: .scale).combined(with: .offset(y: -height - 20))))
            }

            bottomButtons
                .padding(.horizontal, 16)
        }
        .background(Colors.Background.tertiary.edgesIgnoringSafeArea(.all))
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
    }

    @ViewBuilder
    private var amountSummary: some View {
        AmountSummaryView(data:
            AmountSummaryViewData(
                title: Localization.sendAmountLabel,
                amount: "100.00 USDT",
                amountFiat: "99.98$",
                tokenIconInfo: .init(
                    name: "tether",
                    blockchainIconName: "ethereum.fill",
                    imageURL: TokenIconURLBuilder().iconURL(id: "tether"),
                    isCustom: false,
                    customTokenColor: nil
                )
            )
        )
        .matchedGeometryEffect(id: "amount", in: namespace)
        .transition(.asymmetric(insertion: .move(edge: .leading), removal: .opacity.combined(with: .scale)))
    }

    @ViewBuilder
    private var destinationSummary: some View {
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
            .transition(.asymmetric(insertion: .move(edge: .leading), removal: .opacity.combined(with: .scale).combined(with: .offset(y: -height - 20))))
    }

    @ViewBuilder
    private var feeSummary: some View {
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
    }
}

//
// struct SendFinishView_Previews: PreviewProvider {
//    [REDACTED_USERNAME] static var namespace
//
//    static var previews: some View {
//        SendFinishView(namespace: namespace, viewModel: SendFinishViewModel(input: SendFinishViewModelInputMock())!)
//    }
// }
