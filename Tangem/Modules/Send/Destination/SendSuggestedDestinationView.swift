//
//  SendSuggestedDestinationView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

// import BlockchainSdk

class SendSuggestedDestinationViewModel: Identifiable {
    //    let address: String = ""
    //    let type: Type

    //    var address: String {
    //        type.address
    //    }

    let cellViewModels: [SendSuggestedDestinationViewCellModel]

    init(wallets: [SendSuggestedDestinationWallet], recentTransactions: [SendSuggestedDestinationTransactionRecord]) {
        var cellViewModels: [SendSuggestedDestinationViewCellModel] = []

        if !wallets.isEmpty {
            cellViewModels.append(.init(type: .header(title: "My wallets")))
            cellViewModels.append(contentsOf: wallets.map { .init(type: .wallet(wallet: $0)) })
        }

        if !recentTransactions.isEmpty {
            cellViewModels.append(.init(type: .header(title: "Recent")))
            cellViewModels.append(contentsOf: recentTransactions.map { .init(type: .recentTransaction(record: $0)) })
        }

        self.cellViewModels = cellViewModels
    }
}

class SendSuggestedDestinationViewCellModel: Identifiable {
    let type: `Type`

    init(type: Type) {
        self.type = type
    }
}

extension SendSuggestedDestinationViewCellModel {
    enum `Type` {
        case header(title: String)
        case wallet(wallet: SendSuggestedDestinationWallet)
        case recentTransaction(record: SendSuggestedDestinationTransactionRecord)
        //
        //        var address: String {
        //            switch self {
        //            case .myWallet(let wallet):
        //                return address
        //            case .recentTransaction(let record):
        //                return record.address
        //            }
        //        }
    }
}

struct SendSuggestedDestinationWallet {
    let name: String
    let address: String
}

struct SendSuggestedDestinationTransactionRecord {
    let address: String
    let isOutgoing: Bool
    let description: String
}

struct SendSuggestedDestinationView: View {
    private let cellVerticalSpacing: Double = 4
    private let cellHorizontalSpacing: Double = 12
    private let cellVerticalPadding: Double = 14

    let viewModel: SendSuggestedDestinationViewModel

    var body: some View {
        GroupedScrollView {
            GroupedSection(viewModel.cellViewModels) { cellViewModel in
                switch cellViewModel.type {
                case .header(let title):
                    headerView(for: title)
                case .wallet(let wallet):
                    walletView(for: wallet)
                case .recentTransaction(let record):
                    transactionView(for: record)
                }
            }
            .separatorStyle(.none)
            .horizontalPadding(14)
        }
        .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
    }

    @ViewBuilder
    private func headerView(for title: String) -> some View {
        Text(title)
            .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
            .padding(.vertical, 14)
    }

    @ViewBuilder
    private func walletView(for wallet: SendSuggestedDestinationWallet) -> some View {
        HStack(spacing: cellHorizontalSpacing) {
            addressIcon(for: wallet.address)

            VStack(alignment: .leading, spacing: cellVerticalSpacing) {
                addressView(for: wallet.address)

                Text(wallet.name)
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, cellVerticalPadding)
    }

    @ViewBuilder
    private func transactionView(for transaction: SendSuggestedDestinationTransactionRecord) -> some View {
        HStack(spacing: cellHorizontalSpacing) {
            addressIcon(for: transaction.address)

            VStack(alignment: .leading, spacing: cellVerticalSpacing) {
                addressView(for: transaction.address)

                HStack(spacing: 6) {
                    directionArrow(isOutgoing: transaction.isOutgoing)
                        .frame(size: CGSize(bothDimensions: 16))
                        .background(Colors.Background.tertiary)
                        .clipShape(Circle())

                    Text(transaction.description)
                        .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                        .truncationMode(.middle)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, cellVerticalPadding)
    }

    @ViewBuilder
    private func directionArrow(isOutgoing: Bool) -> some View {
        if isOutgoing {
            Assets.Send.arrowUp.image
        } else {
            Assets.Send.arrowDown.image
        }
    }

    private func addressIcon(for address: String) -> some View {
        AddressIconView(viewModel: AddressIconViewModel(address: address))
            .frame(size: CGSize(bothDimensions: 36))
    }

    private func addressView(for address: String) -> some View {
        Text(address)
            .style(Fonts.Regular.subheadline, color: Colors.Text.primary1)
            .truncationMode(.middle)
            .lineLimit(1)
    }
}

#Preview("Different cases") {
    SendSuggestedDestinationView(
        viewModel: SendSuggestedDestinationViewModel(
            wallets: [
                .init(name: "Main Wallet", address: "0x391316d97a07027"),
                .init(name: "Main Wallet", address: "0x391316d97a07027a0702c8A002c8A0C25d8470"),
                .init(name: "Main Wallet Wallet Wallet Wallet Wallet Wallet Wallet Wallet Wallet Wallet Wallet", address: "0x391316d97a07027a0702c8A002c8A0C25d8470"),
            ],
            recentTransactions: [
                .init(address: "0x391316d97a07027a0702c8A002c8A0C25d8470", isOutgoing: false, description: "20,09 USDT, 24.05.2004 at 14:46"),
                .init(address: "0x391316d97a07027a", isOutgoing: true, description: "1 USDT, today at 14:46"),
                .init(address: "0x391316d97a07027a0702c8A002c8A0C25d84700x391316d97a07027a0702c8A002c8A0C25d8470", isOutgoing: false, description: "1 000 000 000 000 000 000 000 000 000 000.123012310 USDT, today at 14:46"),
            ]
        )
    )
}

#Preview("Figma") {
    SendSuggestedDestinationView(
        viewModel: SendSuggestedDestinationViewModel(
            wallets: [
                .init(name: "Main Wallet", address: "0x391316d97a07027a0702c8A002c8A0C25d8470"),
            ],
            recentTransactions: [
                .init(address: "0x391316d97a07027a0702c8A002c8A0C25d84700x391316d97a07027a0702c8A002c8A0C25d8470", isOutgoing: true, description: "1 000 000 000 000 000 000 000 000 000 000.123012310 USDT, today at 14:46"),
                .init(address: "0x391316d97a07027a0702c8A002c8A0C25d8470", isOutgoing: false, description: "20,09 USDT, 24.05.2004 at 14:46"),
            ]
        )
    )
}
