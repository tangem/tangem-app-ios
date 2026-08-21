//
//  TransactionDetailsRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

@MainActor
protocol TransactionDetailsRoutable: AnyObject {
    func openTransactionDetailsURL(_ url: URL)
    func shareFromTransactionDetails(text: String)
    func openTokenFromTransactionDetails(walletModel: any WalletModel, userWalletModel: UserWalletModel)
    func openAddContactFromTransactionDetails(addressBookWallet: AddressBookWallet, prefilledEntries: [AddressBookEntryDraft])
    #if INTERNAL || DEBUG
    func openTransactionDetailsDebug(_ info: TransactionDetailsDebugInfo)
    #endif
    func closeTransactionDetails()
}
