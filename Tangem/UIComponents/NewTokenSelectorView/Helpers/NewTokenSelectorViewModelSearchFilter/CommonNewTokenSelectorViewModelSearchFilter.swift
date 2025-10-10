//
//  CommonNewTokenSelectorViewModelSearchFilter.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

final class CommonNewTokenSelectorViewModelSearchFilter: NewTokenSelectorViewModelSearchFilter {
    func filter(list: NewTokenSelectorList, searchText: String) -> NewTokenSelectorList {
        list.compactMap { wallet -> NewTokenSelectorListItem? in
            let filteredAccountList = wallet.list.compactMap { account -> NewTokenSelectorAccountListItem? in
                let filtered = account.items.filter {
                    $0.walletModel.tokenItem.name.lowercased().contains(searchText.lowercased()) ||
                        $0.walletModel.tokenItem.currencySymbol.lowercased().contains(searchText.lowercased())
                }

                return filtered.nilIfEmpty.map {
                    NewTokenSelectorAccountListItem(account: account.account, items: $0)
                }
            }

            return filteredAccountList.nilIfEmpty.map {
                return NewTokenSelectorListItem(wallet: wallet.wallet, list: $0)
            }
        }
    }
}
