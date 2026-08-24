//
//  TransactionDetailsRouteData.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct TransactionDetailsRouteData {
    let id: TransactionRecord.ID
    let walletModel: any WalletModel
    let userWalletInfo: UserWalletInfo
    let isAccountsMode: Bool
    let addressBookManager: AddressBookManager
}
