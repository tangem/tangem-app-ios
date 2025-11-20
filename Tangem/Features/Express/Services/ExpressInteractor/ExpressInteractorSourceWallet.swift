//
//  ExpressInteractorSourceWallet.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemExpress
import BlockchainSdk

protocol ExpressInteractorSourceWallet: ExpressInteractorDestinationWallet, ExpressSourceWallet {
    var id: WalletModelId { get }
    var isCustom: Bool { get }
    var isMainToken: Bool { get }

    var tokenItem: TokenItem { get }
    var feeTokenItem: TokenItem { get }

    var defaultAddressString: String { get }
    var sendingRestrictions: TransactionSendAvailabilityProvider.SendingRestrictions? { get }
    var amountToCreateAccount: Decimal { get }

    var allowanceService: (any AllowanceService)? { get }
    var availableBalanceProvider: TokenBalanceProvider { get }
    var transactionValidator: any TransactionValidator { get }
    var withdrawalNotificationProvider: (any WithdrawalNotificationProvider)? { get }

    func dexTransactionProcessor() throws -> ExpressDEXTransactionProcessor
    func cexTransactionProcessor() throws -> ExpressCEXTransactionProcessor

    func exploreTransactionURL(for hash: String) -> URL?
}
