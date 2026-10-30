//
//  SendIntentValidator.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemFoundation

enum SendIntentValidator {
    static func canSend(
        _ availability: TokenActionAvailabilityProvider.SendActionAvailabilityStatus,
        hasBlockingPendingTransaction: Bool
    ) -> Bool {
        guard !hasBlockingPendingTransaction else {
            return false
        }

        switch availability {
        case .available, .zeroWalletBalance, .blockchainLoading, .blockchainUnreachable, .hasOnlyCachedBalance:
            return true
        case .oldCard, .cantSignLongTransactions, .hasPendingTransaction, .yieldModuleApproveNeeded, .noAccount:
            return false
        }
    }

    static func isOwnAddress(_ address: String, ownAddresses: [String], blockchain: Blockchain) -> Bool {
        ownAddresses.contains { ownAddress in
            AddressComparator().addressesMatch(ownAddress, address, blockchain: blockchain)
        }
    }

    static func isValidDestination(_ address: String, ownAddresses: [String], blockchain: Blockchain) -> Bool {
        !isOwnAddress(address, ownAddresses: ownAddresses, blockchain: blockchain)
            && MainQRBlockchainResolver.isValidDestinationAddress(address, for: blockchain)
    }

    static func fitsDecimals(_ amount: Decimal, decimalCount: Int) -> Bool {
        amount.rounded(scale: decimalCount, roundingMode: .down) == amount
    }

    static func isValidMemo(_ memo: String?, for blockchain: Blockchain) -> Bool {
        guard let memo = memo?.nilIfEmpty, SendDestinationAdditionalFieldType.type(for: blockchain) != nil else {
            return true
        }

        return (try? TransactionParamsBuilder(blockchain: blockchain).transactionParameters(value: memo)) != nil
    }
}
