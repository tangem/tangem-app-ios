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

struct TransactionDispatcherResultMapper {
    func mapResult(
        _ result: TangemPayWithdrawTransactionResult,
        signer: TangemSignerType?
    ) -> TransactionDispatcherResult {
        let signerType = signer?.analyticsParameterValue ?? Analytics.ParameterValue.unknown
        let currentHost = HostAnalyticsFormatterUtil().formattedHost(from: result.host)

        return TransactionDispatcherResult(
            hash: result.orderID,
            url: nil,
            signerType: signerType.rawValue,
            currentHost: currentHost
        )
    }

    func mapResult(
        _ result: TransactionSendResult,
        blockchain: Blockchain,
        signer: TangemSignerType?,
        isToken: Bool
    ) -> TransactionDispatcherResult {
        let factory = ExternalLinkProviderFactory()
        let provider = factory.makeProvider(for: blockchain)
        let explorerUrl = isToken
            ? provider.tokenUrl(transaction: result.hash)
            : provider.url(transaction: result.hash)

        let signerType = signer?.analyticsParameterValue ?? Analytics.ParameterValue.unknown
        let currentHost = HostAnalyticsFormatterUtil().formattedHost(from: result.currentProviderHost)

        return TransactionDispatcherResult(
            hash: result.hash,
            url: explorerUrl,
            signerType: signerType.rawValue,
            currentHost: currentHost
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
