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
    // MARK: - Private Properties

    private let blockchainDataProvider: BlockchainDataProvider

    // MARK: - Init

    init(blockchainDataProvider: BlockchainDataProvider) {
        self.blockchainDataProvider = blockchainDataProvider
    }

    // MARK: - Implementation

    func mapResult(
        _ result: TransactionSendResult,
        blockchain: Blockchain,
        signer: TangemSignerType?
    ) -> TransactionDispatcherResult {
        let factory = ExternalLinkProviderFactory()
        let provider = factory.makeProvider(for: blockchain)
        let explorerUrl = provider.url(transaction: result.hash)

        let signerType = signer?.analyticsParameterValue ?? Analytics.ParameterValue.unknown
        let blockchainCurrentHost = blockchainDataProvider.currentHost

        return TransactionDispatcherResult(
            hash: result.hash, url: explorerUrl,
            signerType: signerType.rawValue,
            currentHost: blockchainCurrentHost
        )
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
