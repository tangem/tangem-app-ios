//
//  CommonExpressProviderTransactionValidator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress
import BlockchainSdk

struct CommonExpressProviderTransactionValidator: ExpressProviderTransactionValidator {
    // MARK: - Private Properties

    private let tokenItem: TokenItem
    private let hardwareLimitationsUtil: HardwareLimitationsUtil

    // MARK: - Init

    init(tokenItem: TokenItem, hardwareLimitationsUtil: HardwareLimitationsUtil) {
        self.tokenItem = tokenItem
        self.hardwareLimitationsUtil = hardwareLimitationsUtil
    }

    // MARK: - ExpressProviderTransactionValidator

    func validateTransactionSize(data: String) -> Bool {
        do {
            switch tokenItem.blockchain {
            // This logic applies only to the Solana blockchain.
            // For Solana, transaction data is expected to be Base64-encoded,
            // so the string is decoded into Data using base64Decoded().
            // For other blockchains, the method’s behavior must be carefully extended,
            // since the transaction data format and encoding may differ.
            case .solana:
                let transactionData = try Data(data.base64Decoded())
                return try hardwareLimitationsUtil.canHandleTransaction(tokenItem, transaction: transactionData)

            default:
                return true
            }

        } catch {
            return true
        }
    }
}
