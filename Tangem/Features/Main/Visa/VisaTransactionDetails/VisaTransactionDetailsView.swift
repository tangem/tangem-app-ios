//
//  VisaTransactionDetailsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets

struct VisaTransactionDetailsView: View {
    @ObservedObject var viewModel: VisaTransactionDetailsViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 14) {
                ScrollView {
                    VStack(spacing: 14) {
                        fiatTransactionContent

                        ForEach(viewModel.cryptoRequests, id: \.commonTransactionInfo.transactionId) { requestInfo in
                            cryptoRequestView(requestInfo)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }

                Button(action: viewModel.openDispute) {
                    HStack(spacing: 4) {
                        Assets.attention20.image

                        Text(Localization.visaTxDisputeButton)
                            .style(Fonts.Bold.subheadline.weight(.medium), color: Colors.Text.primary1)
                    }
                    .frame(maxWidth: .infinity, minHeight: 40, maxHeight: 40, alignment: .center)
                    .background(
                        Colors.Background.action
                            .cornerRadiusContinuous(10)
                    )
                }
                .padding(.horizontal, 16)
            }
            .navigationTitle(Text(Localization.visaTransactionDetailsHeader))
            .navigationBarTitleDisplayMode(.inline)
            .padding(.bottom, 10)
            .background(Colors.Background.tertiary.ignoresSafeArea())
        }
    }

    private var fiatTransactionContent: some View {
        VStack(spacing: 12) {
            HStack {
                Text(Localization.visaTransactionDetailsTitle)
                    .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

                Spacer()
            }

            VStack(spacing: 0) {
                commonTransactionInfoView(viewModel.fiatTransactionInfo)
                merchantInfo
            }
        }
        .defaultRoundedBackground(with: Colors.Background.action)
    }

    private var merchantInfo: some View {
        VStack(spacing: 0) {
            recordLine(title: Localization.visaTransactionDetailsMerchantName, value: viewModel.merchantName)
            recordLine(title: Localization.visaTransactionDetailsMerchantCity, value: viewModel.merchantCity)
            recordLine(title: Localization.visaTransactionDetailsMerchantCountryCode, value: viewModel.merchantCountryCode)
            recordLine(title: Localization.visaTransactionDetailsMerchantCategoryCode, value: viewModel.merchantCategoryCode)
        }
    }

    private func cryptoRequestView(_ info: CryptoRequestInfo) -> some View {
        VStack(spacing: 12) {
            HStack {
                Text(Localization.visaTransactionDetailsTransactionRequest)
                    .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

                Spacer()

                if let exploreAction = info.exploreAction {
                    Button(action: exploreAction, label: {
                        HStack(spacing: 4) {
                            Assets.compassExplore.image
                                .foregroundColor(Colors.Icon.informative)

                            Text(Localization.commonExplore)
                                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                        }
                    })
                }
            }

            VStack(spacing: 0) {
                commonTransactionInfoView(info.commonTransactionInfo)

                recordLine(title: Localization.visaTransactionDetailsErrorCode, value: info.errorCode)
                recordLine(title: Localization.visaTransactionDetailsTransactionHash, value: info.hash)
                recordLine(title: Localization.visaTransactionDetailsTransactionStatus, value: info.status)
            }
        }
        .defaultRoundedBackground(with: Colors.Background.action)
    }

    private func commonTransactionInfoView(_ info: CommonTransactionInfo) -> some View {
        VStack(spacing: 0) {
            recordLine(title: info.idTitle.description, value: info.transactionId)
            recordLine(title: Localization.visaTransactionDetailsDate, value: info.date)
            recordLine(title: Localization.visaTransactionDetailsType, value: info.type)
            recordLine(title: Localization.visaTransactionDetailsStatus, value: info.status)
            recordLine(title: Localization.visaTransactionDetailsBlockchainAmount, value: info.blockchainAmount)
            recordLine(title: Localization.visaTransactionDetailsTransactionAmount, value: info.transactionAmount)
            recordLine(title: Localization.visaTransactionDetailsCurrencyCode, value: info.currencyCode)
        }
    }

    private func recordLine(title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                .frame(minWidth: 80, alignment: .leading)

            Spacer(minLength: 10)

            Text(value)
                .multilineTextAlignment(.trailing)
                .style(Fonts.Regular.footnote, color: Colors.Text.primary1)
        }
        .padding(.vertical, 8)
    }
}

extension VisaTransactionDetailsView {
    struct CommonTransactionInfo {
        let idTitle: IDTitle
        let transactionId: String
        let date: String
        let type: String
        let status: String
        let blockchainAmount: String
        let transactionAmount: String
        let currencyCode: String

        enum IDTitle {
            case id
            case requestId

            var description: String {
                switch self {
                case .id: return "ID"
                case .requestId: return Localization.visaTransactionDetailsRequestId
                }
            }
        }
    }

    struct CryptoRequestInfo {
        let commonTransactionInfo: CommonTransactionInfo
        let errorCode: String
        let hash: String
        let status: String
        let exploreAction: (() -> Void)?
    }
}

#Preview {
    VisaTransactionDetailsView(viewModel: .uiMock)
}
