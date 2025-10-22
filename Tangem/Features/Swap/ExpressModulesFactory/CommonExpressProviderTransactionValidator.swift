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
    private let requiresTransactionSizeValidation: Bool

    private let solanaTransactionHelper = SolanaTransactionHelper()

    // MARK: - Init

    init(tokenItem: TokenItem, requiresTransactionSizeValidation: Bool) {
        self.tokenItem = tokenItem
        self.requiresTransactionSizeValidation = requiresTransactionSizeValidation
    }

    // MARK: - ExpressProviderTransactionValidator

    func validateTransactionSize(data: String?) -> Bool {
        guard requiresTransactionSizeValidation else {
            return true
        }

        // This logic applies only to the Solana blockchain.
        // For Solana, transaction data is expected to be Base64-encoded,
        // so the string is decoded into Data using base64Decoded().
        // For other blockchains, the method’s behavior must be carefully extended,
        // since the transaction data format and encoding may differ.
        if case .solana = tokenItem.blockchain, let data, let decodedData = try? Data(data.base64Decoded()) {
            return processSolanaTransaction(of: decodedData)
        }

        return true
    }

    // MARK: - Private Implementation

    private func processSolanaTransaction(of transactionData: Data) -> Bool {
        do {
            let transactionWithoutPlaceholders = try solanaTransactionHelper
                .removeSignaturesPlaceholders(from: transactionData)

            switch SolanaTransactionSizeUtils.size(for: transactionWithoutPlaceholders.transaction) {
            case .default:
                return true
            case .long:
                return false
            }
        } catch {
            return false
        }
    }
}
