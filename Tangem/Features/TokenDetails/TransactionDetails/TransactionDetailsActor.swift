//
//  TransactionDetailsActor.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAccounts

enum TransactionDetailsActor: Equatable {
    case address(String, blockiesImage: AddressBlockiesIconViewData)
    case validator(name: String, blockiesImage: AddressBlockiesIconViewData)
    case contact(name: String, AddressBookContactNameIconViewData)
    case account(name: String, icon: AccountIconView.ViewData)
    case wallet(name: String)

    var displayName: String {
        switch self {
        case .address(let address, _): address
        case .validator(let name, _): name
        case .contact(let name, _): name
        case .account(let name, _): name
        case .wallet(let name): name
        }
    }

    var displayNameTruncationMode: Text.TruncationMode {
        switch self {
        case .address: .middle
        case .validator, .contact, .account, .wallet: .tail
        }
    }
}
