//
//  TransactionDetailsActor.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemAccounts

enum TransactionDetailsActor: Equatable {
    case address(short: String, blockiesImage: AddressBlockiesIconViewData)
    case contact(name: String, AddressBookContactNameIconViewData)
    case account(name: String, icon: AccountIconView.ViewData)
    case wallet(name: String)

    var displayName: String {
        switch self {
        case .address(let short, _): short
        case .contact(let name, _): name
        case .account(let name, _): name
        case .wallet(let name): name
        }
    }
}
