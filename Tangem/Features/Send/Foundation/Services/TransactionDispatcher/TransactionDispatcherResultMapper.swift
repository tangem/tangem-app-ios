//
//  TransactionDispatcherResultMapper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSdk
import BlockchainSdk
import TangemFoundation

struct TransactionDispatcherResultMapper {
    func mapResult(
        _ result: TransactionSendResult,
        blockchain: Blockchain,
        signer: TangemSignerType?
    ) -> TransactionDispatcherResult {
        let factory = ExternalLinkProviderFactory()
        let provider = factory.makeProvider(for: blockchain)
        let explorerUrl = provider.url(transaction: result.hash)

        let signerType = signer?.analyticsParameterValue ?? Analytics.ParameterValue.unknown
        return TransactionDispatcherResult(hash: result.hash, url: explorerUrl, signerType: signerType.rawValue)
    }

    func mapError(_ error: UniversalError, transaction: TransactionDispatcherTransactionType) -> TransactionDispatcherResult.Error {
        let sendError = error as? SendTxError ?? SendTxError(error: error)
        let internalError = sendError.error

        if internalError.isCancellationError {
            return .userCancelled
        }

        return .sendTxError(transaction: transaction, error: sendError)
    }
}
