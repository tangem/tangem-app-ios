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

                    statusesView
                }
                .defaultRoundedBackground(with: Colors.Background.action)
            }
            .padding(.vertical, 22)
            .padding(.horizontal, 16)
        }
        .animation(.default, value: viewModel.statusesList)
        .animation(.default, value: viewModel.currentStatusIndex)
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

    @ViewBuilder
    private var statusesView: some View {
        VStack(spacing: 0) {
            ForEach(0 ..< 4) { index in
                let status = viewModel.statusesList[index]
                statusRow(isFirstRow: index == 0, info: status)
            }
        }
    }

    private func statusRow(isFirstRow: Bool, info: StatusRowData) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if !isFirstRow {
                HStack {
                    Assets.verticalLine.image
                        .foregroundColor(info.state.lineColor)
                        .opacity(info.state.lineOpacity)
                }
            }

            HStack(spacing: 12) {
                ZStack {
                    Assets.circleOutline20.image
                        .foregroundColor(info.state.circleColor)
                        .opacity(info.state.circleOpacity)

                    info.state.foregroundIcon
                }

                Text(info.title)
                    .style(Fonts.Regular.footnote, color: info.state.textColor)

                Spacer()
            }
        }
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

extension PendingExpressTxStatusBottomSheetView {
    struct StatusRowData: Identifiable, Hashable {
        enum State: Hashable {
            case empty
            case loader
            case checkmark
            case cross(passed: Bool)
            case exclamationMark

            @ViewBuilder
            var foregroundIcon: some View {
                Group {
                    switch self {
                    case .empty: EmptyView()
                    case .loader:
                        ProgressView()
                            .progressViewStyle(.circular)
                    case .checkmark:
                        Assets.checkmark20.image
                    case .cross:
                        Assets.cross20.image
                    case .exclamationMark:
                        Assets.exclamationMark20.image
                    }
                }
                .foregroundColor(iconColor)
                .frame(size: .init(bothDimensions: 20))
            }

            var circleColor: Color {
                switch self {
                case .empty, .checkmark: return Colors.Field.focused
                case .loader: return Color.clear
                case .cross(let passed):
                    return passed ? Colors.Field.focused : Colors.Icon.warning
                case .exclamationMark: return Colors.Icon.attention
                }
            }

            var iconColor: Color {
                switch self {
                case .empty: return Color.clear
                case .loader, .checkmark: return Colors.Text.primary1
                case .cross(let passed):
                    return passed ? Colors.Text.primary1 : Colors.Icon.warning
                case .exclamationMark: return Colors.Icon.attention
                }
            }

            var lineColor: Color {
                switch self {
                case .empty, .loader, .checkmark, .exclamationMark: return Colors.Field.focused
                case .cross(let passed):
                    return passed ? Colors.Field.focused : Colors.Icon.warning
                }
            }

            var textColor: Color {
                switch self {
                case .checkmark, .loader: return Colors.Text.primary1
                case .empty: return Colors.Text.disabled
                case .cross(let passed):
                    return passed ? Colors.Text.primary1 : Colors.Text.warning
                case .exclamationMark: return Colors.Text.attention
                }
            }

            var lineOpacity: Double {
                switch self {
                case .empty, .loader, .checkmark, .exclamationMark: return 1.0
                case .cross(let passed):
                    return passed ? 1.0 : 0.4
                }
            }

            var circleOpacity: Double {
                switch self {
                case .empty, .loader, .checkmark: return 1.0
                case .exclamationMark: return 0.4
                case .cross(let passed):
                    return passed ? 1.0 : 0.4
                }
            }
        }

        let title: String
        let state: State

        var id: Int { hashValue }
    }
}

struct ExpressPendingTxStatusBottomSheetView_Preview: PreviewProvider {
    static var defaultViewModel: PendingExpressTxStatusBottomSheetViewModel = {
        let factory = PendingExpressTransactionFactory()
        let userWalletId = "21321"
        let tokenItem = TokenItem.blockchain(.polygon(testnet: false))
        let blockchainNetwork = BlockchainNetwork(.polygon(testnet: false))
        let record = ExpressPendingTransactionRecord(
            userWalletId: userWalletId,
            expressTransactionId: "1bd298ee-2e99-406e-a25f-a715bb87e806",
            transactionType: .send,
            transactionHash: "13213124321",
            sourceTokenTxInfo: .init(
                tokenItem: tokenItem,
                blockchainNetwork: blockchainNetwork,
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
            provider: ExpressPendingTransactionRecord.Provider(provider: .init(id: "changenow", name: "ChangeNow", url: URL(string: "https://s3.eu-central-1.amazonaws.com/tangem.api/express/changenow_512.png"), type: .cex)),
            date: Date(),
            externalTxId: "a34883e049a416",
            externalTxURL: "https://changenow.io/exchange/txs/a34883e049a416"
        )
        let pendingTransaction = factory.buildPendingExpressTransaction(currentExpressStatus: .sending, for: record)
        return .init(
            pendingTransaction: pendingTransaction,
            pendingTransactionsManager: CommonPendingExpressTransactionsManager(
                userWalletId: userWalletId,
                blockchainNetwork: blockchainNetwork,
                tokenItem: tokenItem
            )
        )
    }()

    static var previews: some View {
        Group {
            ZStack {
                Colors.Background.secondary.edgesIgnoringSafeArea(.all)

                PendingExpressTxStatusBottomSheetView(viewModel: defaultViewModel)
            }
        }
    }
}
