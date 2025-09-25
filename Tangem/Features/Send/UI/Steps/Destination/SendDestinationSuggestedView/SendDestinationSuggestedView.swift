//
//  SendDestinationSuggestedView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct SendDestinationSuggestedView: View {
    let viewModel: SendDestinationSuggestedViewModel

    private let cellVerticalSpacing: Double = 4
    private let cellHorizontalSpacing: Double = 12

    var body: some View {
        GroupedSection(viewModel.cellViewModels) { cellViewModel in
            let index = viewModel.cellViewModels.firstIndex(where: { $0.id == cellViewModel.id }) ?? -1

            if let tapAction = cellViewModel.tapAction {
                cellView(for: cellViewModel.type, index: index)
                    .contentShape(Rectangle())
                    .onTapGesture(perform: tapAction)
            } else {
                cellView(for: cellViewModel.type, index: index)
            }
        }
        .backgroundColor(Colors.Background.action)
        .interItemSpacing(0)
        .separatorStyle(.none)
        .backgroundColor(Colors.Background.action)
    }

    @ViewBuilder
    private func cellView(for type: SendDestinationSuggestedViewModel.CellModel.`Type`, index: Int) -> some View {
        switch type {
        case .header(let title):
            headerView(for: title)
        case .wallet(let wallet, let addressIconViewModel):
            walletView(for: wallet, addressIconViewModel: addressIconViewModel)
        case .recentTransaction(let record, let addressIconViewModel):
            transactionView(for: record, addressIconViewModel: addressIconViewModel)
        }
    }

    @ViewBuilder
    private func headerView(for title: String) -> some View {
        Text(title)
            .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
            .padding(.top, 16)
    }

    @ViewBuilder
    private func walletView(for wallet: SendDestinationSuggestedWallet, addressIconViewModel: AddressIconViewModel) -> some View {
        HStack(spacing: cellHorizontalSpacing) {
            addressIcon(with: addressIconViewModel)

            VStack(alignment: .leading, spacing: cellVerticalSpacing) {
                addressView(for: wallet.address)

                Text(wallet.name)
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private func transactionView(for transaction: SendDestinationSuggestedTransactionRecord, addressIconViewModel: AddressIconViewModel) -> some View {
        HStack(spacing: cellHorizontalSpacing) {
            addressIcon(with: addressIconViewModel)

            VStack(alignment: .leading, spacing: cellVerticalSpacing) {
                addressView(for: transaction.address)

                HStack(spacing: 6) {
                    directionArrow(isOutgoing: transaction.isOutgoing)
                        .frame(size: CGSize(bothDimensions: 16))
                        .background(Colors.Background.tertiary)
                        .clipShape(Circle())

                    SensitiveText(builder: transaction.description, sensitive: transaction.amountFormatted)
                        .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                        .truncationMode(.middle)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 14)
    }

    @ViewBuilder
    private func directionArrow(isOutgoing: Bool) -> some View {
        if isOutgoing {
            Assets.Send.arrowUp.image
        } else {
            Assets.Send.arrowDown.image
        }
    }

    private func addressIcon(with viewModel: AddressIconViewModel) -> some View {
        AddressIconView(viewModel: viewModel)
            .frame(size: CGSize(bothDimensions: 36))
    }

    private func addressView(for address: String) -> some View {
        HStack(spacing: 0) {
            Text(address)
                .style(Fonts.Regular.subheadline, color: Colors.Text.primary1)
                .truncationMode(.middle)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            // HACK: SwiftUI cannot truncate the text in the middle and align it to the leading edge without a little push
            Spacer(minLength: 10)
        }
    }
}

#Preview("Different cases") {
    SendDestinationSuggestedView(
        viewModel: SendDestinationSuggestedViewModel(
            wallets: [
                .init(name: "Main Wallet", address: "0x391316d97a07027"),
                .init(name: "Main Wallet", address: "0x391316d97a07027a0702c8A002c8A0C25d8470"),
                .init(name: "Main Wallet Wallet Wallet Wallet Wallet Wallet Wallet Wallet Wallet Wallet Wallet", address: "0x391316d97a07027a0702c8A002c8A0C25d8470"),
            ],
            recentTransactions: [
                .init(address: "0x391316d97a07027a0702c8A002c8A0C25d8470", additionalField: nil, isOutgoing: false, date: .init(), amountFormatted: "20,09 USDT", dateFormatted: "24.05.2004 at 14:46"),
                .init(address: "0x391316d97a07027a", additionalField: "123142", isOutgoing: true, date: .init(), amountFormatted: "1 USDT", dateFormatted: "today at 14:46"),
                .init(address: "0x391316d97a07027a0702c8A002c8A0C25d84700x391316d97a07027a0702c8A002c8A0C25d8470", additionalField: nil, isOutgoing: false, date: .init(), amountFormatted: "1 000 000 000 000 000 000 000 000 000 000.123012310 USDT", dateFormatted: "today at 14:46"),
            ],
            tapAction: { _ in }
        )
    )
}

#Preview("Figma") {
    GroupedScrollView {
        SendDestinationSuggestedView(
            viewModel: SendDestinationSuggestedViewModel(
                wallets: [
                    .init(name: "Main Wallet", address: "0x391316d97a07027a0702c8A002c8A0C25d8470"),
                ],
                recentTransactions: [
                    .init(address: "0x391316d97a07027a0702c8A002c8A0C25d84700x391316d97a07027a0702c8A002c8A0C25d8470", additionalField: nil, isOutgoing: true, date: .init(), amountFormatted: "1 000 000 000 000 000 000 000 000 000 000.123012310 USDT", dateFormatted: "today at 14:46"),
                    .init(address: "0x391316d97a07027a0702c8A002c8A0C25d8470", additionalField: nil, isOutgoing: false, date: .init(), amountFormatted: "20,09 USDT", dateFormatted: "24.05.2004 at 14:46"),
                ],
                tapAction: { _ in }
            )
        )
    }
    .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
}
