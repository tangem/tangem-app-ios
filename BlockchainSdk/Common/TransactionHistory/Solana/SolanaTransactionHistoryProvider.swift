//
//  SolanaTransactionHistoryProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation
import TangemNetworkUtils

final class SolanaTransactionHistoryProvider: TransactionHistoryProvider {
    private let node: NodeInfo
    private let networkProvider: TangemProvider<SolanaTransactionHistoryTarget>
    private let mapper: SolanaTransactionHistoryMapper

    private var before: String?
    private var hasReachedEnd = false

    init(
        node: NodeInfo,
        networkConfiguration: TangemProviderConfiguration,
        mapper: SolanaTransactionHistoryMapper
    ) {
        self.node = node
        networkProvider = .init(configuration: networkConfiguration)
        self.mapper = mapper
    }

    var canFetchHistory: Bool {
        !hasReachedEnd
    }

    var description: String {
        objectDescription(
            self,
            userInfo: [
                "host": node.host,
                "before": before ?? "-",
                "hasReachedEnd": hasReachedEnd,
            ]
        )
    }

    func reset() {
        before = nil
        hasReachedEnd = false
        mapper.reset()
    }

    func loadTransactionHistory(request: TransactionHistory.Request) -> AnyPublisher<TransactionHistory.Response, Error> {
        fetchSignatures(address: request.address, limit: request.limit)
            .flatMap { [weak self] signatures -> AnyPublisher<TransactionHistory.Response, Error> in
                guard let self else {
                    return .anyFail(error: BlockchainSdkError.empty)
                }

                guard !signatures.isEmpty else {
                    return .justWithError(output: .init(records: []))
                }

                return fetchTransactions(signatures: signatures)
                    .tryMap { [weak self] transactions -> TransactionHistory.Response in
                        guard let self else {
                            throw BlockchainSdkError.empty
                        }

                        let records = try mapper.mapToTransactionRecords(
                            transactions,
                            walletAddress: request.address,
                            amountType: request.amountType
                        )
                        .filter { record in
                            self.shouldBeIncludedInHistory(
                                amountType: request.amountType,
                                record: record
                            )
                        }

                        return .init(records: records)
                    }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
}

private extension SolanaTransactionHistoryProvider {
    func fetchSignatures(address: String, limit: Int) -> AnyPublisher<[String], Error> {
        let target = SolanaTransactionHistoryTarget(
            node: node,
            request: .getSignaturesForAddress(address: address, limit: limit, before: before)
        )

        return networkProvider.requestPublisher(target)
            .filterSuccessfulStatusAndRedirectCodes()
            .map(JSONRPC.Response<[SolanaTransactionHistoryDTO.SignatureItem], JSONRPC.APIError>.self)
            .tryMap { [weak self] response -> [String] in
                guard let self else {
                    throw BlockchainSdkError.empty
                }

                let result = try response.result.get()
                let signatures = result.map(\.signature)

                before = signatures.last
                hasReachedEnd = signatures.isEmpty || signatures.count < limit

                return signatures
            }
            .eraseToAnyPublisher()
    }

    func fetchTransactions(signatures: [String]) -> AnyPublisher<[SolanaTransactionHistoryDTO.TransactionDetails], Error> {
        let publishers: [AnyPublisher<SolanaTransactionHistoryDTO.TransactionDetails?, Error>] = signatures.map { signature in
            let target = SolanaTransactionHistoryTarget(node: node, request: .getTransaction(signature: signature))
            return networkProvider.requestPublisher(target)
                .filterSuccessfulStatusAndRedirectCodes()
                .map(JSONRPC.Response<SolanaTransactionHistoryDTO.TransactionDetails?, JSONRPC.APIError>.self)
                .tryMap { try $0.result.get() }
                .eraseToAnyPublisher()
        }

        return Publishers.Sequence(sequence: publishers)
            .flatMap(maxPublishers: .max(1)) { $0 }
            .collect()
            .map { details in
                details.compactMap { $0 }
            }
            .eraseToAnyPublisher()
    }
}
