//
//  PendingExpressTxStatusBottomSheetView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct PendingExpressTxStatusBottomSheetView: View {
    @ObservedObject var viewModel: PendingExpressTxStatusBottomSheetViewModel

    private let tokenIconSize = CGSize(bothDimensions: 36)

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                Text(Localization.expressExchangeStatusTitle)
                    .style(Fonts.Regular.headline, color: Colors.Text.primary1)

                Text(Localization.expressExchangeStatusSubtitle)
                    .style(Fonts.Regular.footnote, color: Colors.Text.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 50)
            .padding(.vertical, 10)

            VStack(spacing: 14) {
                amountsView

                providerView

                VStack(spacing: 14) {
                    HStack(spacing: 10) {
                        exchangeByTitle

                        Spacer()

                        Button(action: viewModel.openProvider, label: {
                            HStack(spacing: 4) {
                                Assets.arrowRightUpMini.image
                                    .renderingMode(.template)
                                    .foregroundColor(Colors.Text.tertiary)

                                Text(Localization.expressGoToProvider)
                                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                            }
                        })
                    }

                    VStack {
                        HStack(alignment: .top, spacing: 12) {
                            VStack {}

                            Text(Localization.expressExchangeStatusReceived)
                                .style(Fonts.Regular.footnote, color: Colors.Text.primary1)
                        }
                    }
                }
                .defaultRoundedBackground(with: Colors.Background.action)
            }
            .padding(.vertical, 22)
            .padding(.horizontal, 16)
        }
        .sheet(item: $viewModel.modalWebViewModel) {
            WebViewContainer(viewModel: $0)
        }
    }

    private var amountsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 0) {
                Text(Localization.expressEstimatedAmount)
                    .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

                Spacer(minLength: 8)

                Text(viewModel.timeString)
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
            }

            HStack(spacing: 12) {
                tokenInfo(
                    with: viewModel.sourceTokenIconInfo,
                    cryptoAmountText: viewModel.sourceAmountText,
                    fiatAmountTextState: viewModel.sourceFiatAmountTextState
                )

                Assets.approx.image
                    .renderingMode(.template)
                    .foregroundColor(Colors.Text.tertiary)

                tokenInfo(
                    with: viewModel.destinationTokenIconInfo,
                    cryptoAmountText: viewModel.destinationAmountText,
                    fiatAmountTextState: viewModel.destinationFiatAmountTextState
                )
            }
        }
        .defaultRoundedBackground(with: Colors.Background.action)
    }

    private var providerView: some View {
        VStack(spacing: 12) {
            HStack {
                exchangeByTitle

                Spacer()
            }

            HStack(spacing: 12) {
                IconView(
                    url: viewModel.providerIconURL,
                    size: .init(bothDimensions: 36)
                )

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Text(viewModel.providerName)
                            .style(Fonts.Regular.footnote, color: Colors.Text.primary1)

                        Text(viewModel.providerType)
                            .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                    }

                    HStack {
                        Text(Localization.expressFloatingRate)
                            .style(Fonts.Regular.subheadline, color: Colors.Text.tertiary)
                    }
                }
                Spacer()
            }
        }
        .defaultRoundedBackground(with: Colors.Background.action)
    }

    private var exchangeByTitle: some View {
        Text(Localization.expressExchangeBy(viewModel.providerName))
            .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
    }

    private func tokenInfo(with tokenIconInfo: TokenIconInfo, cryptoAmountText: String, fiatAmountTextState: LoadableTextView.State) -> some View {
        HStack(spacing: 12) {
            TokenIcon(tokenIconInfo: tokenIconInfo, size: tokenIconSize)

            VStack(alignment: .leading, spacing: 2) {
                SensitiveText(cryptoAmountText)

                    .style(Fonts.Regular.footnote, color: Colors.Text.primary1)

                LoadableTextView(
                    state: fiatAmountTextState,
                    font: Fonts.Regular.caption1,
                    textColor: Colors.Text.tertiary,
                    loaderSize: .init(width: 52, height: 12),
                    isSensitiveText: true
                )
            }
        }
    }

}

struct ExpressPendingTxStatusBottomSheetView_Preview: PreviewProvider {
    static var defaultViewModel: PendingExpressTxStatusBottomSheetViewModel = .init(
        record: .init(
            userWalletId: "",
            expressTransactionId: "1bd298ee-2e99-406e-a25f-a715bb87e806",
            transactionType: .send,
            transactionHash: "13213124321",
            sourceTokenTxInfo: .init(
                tokenItem: .blockchain(.polygon(testnet: false)),
                blockchainNetwork: .init(.polygon(testnet: false)),
                amount: 10,
                isCustom: true
            ),
            destinationTokenTxInfo: .init(
                tokenItem: .token(.shibaInuMock, .ethereum(testnet: false)),
                blockchainNetwork: .init(.ethereum(testnet: false)),
                amount: 1,
                isCustom: false
            ),
            fee: 0.021351,
            provider: .init(id: .changeNow, name: "ChangeNow", url: URL(string: "https://s3.eu-central-1.amazonaws.com/tangem.api/express/changenow_512.png"), type: .cex),
            date: Date(),
            externalTxId: "a34883e049a416",
            externalTxURL: "https://changenow.io/exchange/txs/a34883e049a416"
        )
    )

    static var previews: some View {
        Group {
            ZStack {
                Colors.Background.secondary.edgesIgnoringSafeArea(.all)

                PendingExpressTxStatusBottomSheetView(viewModel: defaultViewModel)
            }
        }
    }
}
