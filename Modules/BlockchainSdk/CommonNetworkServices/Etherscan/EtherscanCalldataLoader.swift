//
//  EtherscanCalldataLoader.swift
//  BlockchainSdk
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemNetworkUtils
import TangemFoundation

final class EtherscanCalldataLoader {
    private let networkProvider: TangemProvider<EtherscanTransactionHistoryTarget>
    private let targetConfiguration: EtherscanTransactionHistoryTarget.Configuration
    private let calldataByHash = OSAllocatedUnfairLock(initialState: [String: String]())

    init(
        networkProvider: TangemProvider<EtherscanTransactionHistoryTarget>,
        targetConfiguration: EtherscanTransactionHistoryTarget.Configuration
    ) {
        self.networkProvider = networkProvider
        self.targetConfiguration = targetConfiguration
    }

    func restoringMissingCalldata(in result: EtherscanTransactionHistoryResult) async -> EtherscanTransactionHistoryResult {
        guard case .transactions(let transactions) = result.result else {
            return result
        }

        let hashes = transactions.filter(\.isUpgradeToAndCallWithoutCalldata).map(\.hash).unique()

        for hash in hashes where calldata(forHash: hash) == nil {
            do {
                guard let calldata = try await loadCalldata(ofTransactionWithHash: hash) else {
                    BSDKLogger.warning("Etherscan returned no calldata for transaction \(hash)")
                    continue
                }

                calldataByHash.withLock { $0[hash] = calldata }
            } catch {
                guard !Task.isCancelled else {
                    return result
                }

                BSDKLogger.error("Failed to load calldata of transaction \(hash)", error: error)

                if case EtherscanAPIError.maxRateLimitReached = error {
                    break
                }
            }
        }

        let restoredTransactions = transactions.map { transaction in
            guard transaction.isUpgradeToAndCallWithoutCalldata, let calldata = calldata(forHash: transaction.hash) else {
                return transaction
            }

            return transaction.replacingInput(with: calldata)
        }

        return EtherscanTransactionHistoryResult(
            status: result.status,
            message: result.message,
            result: .transactions(restoredTransactions)
        )
    }

    private func calldata(forHash hash: String) -> String? {
        calldataByHash.withLock { $0[hash] }
    }

    private func loadCalldata(ofTransactionWithHash hash: String) async throws -> String? {
        let target = EtherscanTransactionHistoryTarget(configuration: targetConfiguration, target: .getTransaction(hash: hash))

        for retryAttempt in 0 ... Constants.maxRetryCount {
            if retryAttempt > 0 {
                try await Task.sleep(nanoseconds: ExponentialBackoffInterval(retryAttempt: retryAttempt)())
            }

            let response = try await networkProvider
                .request(target)
                .filterSuccessfulStatusAndRedirectCodes()

            if let failure = try? response.map(EtherscanTransactionHistoryResult.self), failure.isRateLimitReached {
                continue
            }

            return try response.map(JSONRPC.DefaultResponse<EthereumTransaction?>.self).result.get()?.input
        }

        throw EtherscanAPIError.maxRateLimitReached
    }
}

// MARK: - Constants

private extension EtherscanCalldataLoader {
    enum Constants {
        static var maxRetryCount: Int { 1 }
    }
}

// MARK: - Convenience extensions

private extension EtherscanTransactionHistoryResult.Transaction {
    var isUpgradeToAndCallWithoutCalldata: Bool {
        methodId?.caseInsensitiveEquals(to: UpgradeToAndCallMethod.methodId) == true
            && !(input.map(UpgradeToAndCallMethod.isEncodedCall) ?? false)
    }

    func replacingInput(with input: String) -> Self {
        .init(
            confirmations: confirmations,
            contractAddress: contractAddress,
            from: from,
            functionName: functionName,
            methodId: methodId,
            gasPrice: gasPrice,
            gasUsed: gasUsed,
            hash: hash,
            input: input,
            isError: isError,
            timeStamp: timeStamp,
            to: to,
            txReceiptStatus: txReceiptStatus,
            value: value
        )
    }
}
