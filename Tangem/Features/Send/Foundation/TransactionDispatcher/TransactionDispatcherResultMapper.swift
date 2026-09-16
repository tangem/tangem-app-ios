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
import TangemVisa
import TangemFoundation
import TangemPay
import TangemPolymarket

struct TransactionDispatcherResultMapper {
    func mapResult(
        _ result: TangemPayWithdrawTransactionResult,
        txHash: String,
        signer: TangemSignerType?
    ) -> TransactionDispatcherResult {
        let signerType = signer?.analyticsParameterValue ?? Analytics.ParameterValue.unknown
        let currentHost = HostAnalyticsFormatterUtil().formattedHost(from: result.host)

        return TransactionDispatcherResult(
            hash: txHash,
            url: nil,
            signerType: signerType.rawValue,
            currentHost: currentHost
        )
    }

    /// A joint account's operation is no transaction yet: it has no hash and no explorer page until the relayer
    /// executes it, so the id the backend minted stands where the hash goes, and the host is the backend's.
    func mapResult(_ operation: JointAccountOperation, signer: TangemSignerType?) -> TransactionDispatcherResult {
        let signerType = signer?.analyticsParameterValue ?? Analytics.ParameterValue.unknown
        let currentHost = HostAnalyticsFormatterUtil().formattedHost(from: AppEnvironment.current.apiBaseUrl.absoluteString)

        return TransactionDispatcherResult(
            hash: operation.id,
            url: nil,
            signerType: signerType.rawValue,
            currentHost: currentHost
        )
    }

    func mapResult(
        _ record: PolymarketWithdrawRecord,
        host: String,
        signer: TangemSignerType?
    ) -> TransactionDispatcherResult {
        let signerType = signer?.analyticsParameterValue ?? Analytics.ParameterValue.unknown

        let explorerURL = record.transactionHash.flatMap { hash in
            ExternalLinkProviderFactory()
                .makeProvider(for: PolymarketUtilities.blockchain)
                .url(transaction: hash)
        }

        return TransactionDispatcherResult(
            // The relayer does not always attach a Polygon hash, and the withdrawal is identified by its
            // own id everywhere else, so that is what the finish step falls back to.
            hash: record.transactionHash ?? record.transactionId,
            url: explorerURL,
            signerType: signerType.rawValue,
            currentHost: HostAnalyticsFormatterUtil().formattedHost(from: host)
        )
    }

    func mapResult(
        _ result: GaslessTransactionSendResult,
        blockchain: Blockchain,
        signer: TangemSignerType?,
        isToken: Bool
    ) -> TransactionDispatcherResult {
        return mapCommonSendResult(
            hash: result.hash,
            currentProviderHost: result.currentProviderHost,
            blockchain: blockchain,
            signer: signer,
            isToken: isToken
        )
    }

    func mapResult(
        _ result: TransactionSendResult,
        blockchain: Blockchain,
        signer: TangemSignerType?,
        isToken: Bool
    ) -> TransactionDispatcherResult {
        return mapCommonSendResult(
            hash: result.hash,
            currentProviderHost: result.currentProviderHost,
            blockchain: blockchain,
            signer: signer,
            isToken: isToken
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

    // MARK: - Private Implementation

    private func mapCommonSendResult(
        hash: String,
        currentProviderHost: String,
        blockchain: Blockchain,
        signer: TangemSignerType?,
        isToken: Bool
    ) -> TransactionDispatcherResult {
        let factory = ExternalLinkProviderFactory()
        let provider = factory.makeProvider(for: blockchain)
        let explorerUrl = isToken
            ? provider.tokenUrl(transaction: hash)
            : provider.url(transaction: hash)

        let signerType = signer?.analyticsParameterValue ?? Analytics.ParameterValue.unknown
        let currentHost = HostAnalyticsFormatterUtil().formattedHost(from: currentProviderHost)

        return TransactionDispatcherResult(
            hash: hash,
            url: explorerUrl,
            signerType: signerType.rawValue,
            currentHost: currentHost
        )
    }
}
