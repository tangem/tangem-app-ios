//
//  ForYouAddFundsTokenSelectorViewModel+SectionsFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemUI
import TangemAccounts

private typealias Holding = ForYouAddFundsTokenSelectorViewModel.Holding
private typealias AccountGroup = ForYouAddFundsTokenSelectorViewModel.SectionsFactory.AccountGroup

extension ForYouAddFundsTokenSelectorViewModel {
    enum SectionsFactory {
        /// One section per owning account, in first-seen wallet order.
        static func make(
            holdings: [Holding],
            iconBuilder: TokenIconInfoBuilder = .init(),
            onSelect: @escaping (Holding) -> Void
        ) -> [Section] {
            holdings.groupedByAccount().makeSections(iconBuilder: iconBuilder, onSelect: onSelect)
        }
    }
}

// MARK: - Account group

private extension ForYouAddFundsTokenSelectorViewModel.SectionsFactory {
    struct AccountGroup {
        let id: String
        let account: any CryptoAccountModel
        let holdings: [Holding]

        func section(
            iconBuilder: TokenIconInfoBuilder,
            onSelect: @escaping (Holding) -> Void
        ) -> ForYouAddFundsTokenSelectorViewModel.Section {
            ForYouAddFundsTokenSelectorViewModel.Section(
                id: id,
                accountIcon: AccountModelUtils.UI.iconViewData(accountModel: account),
                accountName: account.name,
                rows: holdings.map { $0.row(iconBuilder: iconBuilder, onSelect: onSelect) }
            )
        }
    }
}

// MARK: - Grouping pipeline

private extension Array where Element == Holding {
    /// Buckets holdings by their owning account, keeping first-seen (wallet) order.
    func groupedByAccount() -> [AccountGroup] {
        let grouped = grouped(by: \.accountKey)

        return unique(by: \.accountKey).compactMap { sample in
            grouped[sample.accountKey].map {
                AccountGroup(
                    id: sample.accountKey,
                    account: sample.account,
                    holdings: $0
                )
            }
        }
    }
}

private extension Array where Element == AccountGroup {
    func makeSections(
        iconBuilder: TokenIconInfoBuilder,
        onSelect: @escaping (Holding) -> Void
    ) -> [ForYouAddFundsTokenSelectorViewModel.Section] {
        map { $0.section(iconBuilder: iconBuilder, onSelect: onSelect) }
    }
}

// MARK: - Holding → row

private extension Holding {
    var accountKey: String {
        "\(userWalletModel.userWalletId.stringValue)_\(account.id.toPersistentIdentifier())"
    }

    /// `walletModel.id.id` collides across wallets holding the same token, so prefix the wallet id.
    var rowId: String {
        "\(userWalletModel.userWalletId.stringValue)_\(walletModel.id.id)"
    }

    func row(
        iconBuilder: TokenIconInfoBuilder,
        onSelect: @escaping (Holding) -> Void
    ) -> ForYouAddFundsTokenSelectorViewModel.RowData {
        let tokenItem = walletModel.tokenItem

        return .init(
            id: rowId,
            tokenIconInfo: iconBuilder.build(from: tokenItem, isCustom: walletModel.isCustom),
            name: tokenItem.name,
            network: tokenItem.networkName,
            fiat: walletModel.fiatTotalTokenBalanceProvider.formattedBalanceType.value,
            crypto: walletModel.totalTokenBalanceProvider.formattedBalanceType.value,
            onTap: { onSelect(self) }
        )
    }
}
