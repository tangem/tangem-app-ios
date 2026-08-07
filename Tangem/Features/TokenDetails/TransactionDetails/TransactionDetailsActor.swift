//
//  TransactionDetailsActor.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemAccounts
import TangemLocalization

enum TransactionDetailsActor: Equatable {
    case address(short: String, blockiesImage: AddressBlockiesIconViewData)
    case contact(name: String, AddressBookContactNameIconViewData)
    case account(name: String, icon: AccountIconView.ViewData)
    case accountInWallet(accountName: String, accountIcon: AccountIconView.ViewData, walletName: String)
    case wallet(name: String)

    var displayName: String {
        switch self {
        case .address(let short, _): short
        case .contact(let name, _): name
        case .account(let name, _): name
        // [REDACTED_TODO_COMMENT]
        case .accountInWallet(let accountName, _, let walletName): "\(accountName) \(Localization.commonIn) \(walletName)"
        case .wallet(let name): name
        }
    }
}
