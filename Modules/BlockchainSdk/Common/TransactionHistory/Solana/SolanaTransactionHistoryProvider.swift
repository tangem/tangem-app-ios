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
    private let configuration: SolanaTransactionHistoryTarget.Configuration
    private let networkProvider: TangemProvider<SolanaTransactionHistoryTarget>
    private let mapper: SolanaTransactionHistoryMapper

    private var before: String?
    private var hasReachedEnd = false

    init(
        configuration: SolanaTransactionHistoryTarget.Configuration,
        networkConfiguration: TangemProviderConfiguration,
        mapper: SolanaTransactionHistoryMapper
    ) {
        self.configuration = configuration
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
                "configuration": configuration,
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
        guard case .address(let address) = request.key else {
            return .anyFail(error: TransactionHistory.ProviderError.requestKeyNotSupported)
        }

        return resolveSignaturesAddress(owner: address, amountType: request.amountType)
            .flatMap { [weak self] signaturesAddress -> AnyPublisher<[String], Error> in
                guard let self else {
                    return .anyFail(error: BlockchainSdkError.empty)
                }

                guard let signaturesAddress else {
                    hasReachedEnd = true
                    return .justWithError(output: [])
                }

                return fetchSignatures(address: signaturesAddress, limit: request.limit)
            }
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
                            walletAddress: address,
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
    func resolveSignaturesAddress(owner: String, amountType: Amount.AmountType) -> AnyPublisher<String?, Error> {
        switch amountType {
        case .coin, .reserve:
            return .justWithError(output: owner)
        case .token(let token):
            return fetchTokenAccountAddress(owner: owner, mint: token.contractAddress)
        case .feeResource:
            return .justWithError(output: nil)
        }
    }

    func fetchTokenAccountAddress(owner: String, mint: String) -> AnyPublisher<String?, Error> {
        let target = SolanaTransactionHistoryTarget(
            configuration: configuration,
            request: .getTokenAccountsByOwner(owner: owner, mint: mint)
        )

        return networkProvider.requestPublisher(target)
            .filterSuccessfulStatusAndRedirectCodes()
            .map(JSONRPC.Response<SolanaTransactionHistoryDTO.TokenAccounts, JSONRPC.APIError>.self)
            .tryMap { response in
                let result = try response.result.get()
                return result.value.first?.pubkey
            }
            .eraseToAnyPublisher()
    }

    func fetchSignatures(address: String, limit: Int) -> AnyPublisher<[String], Error> {
        let target = SolanaTransactionHistoryTarget(
            configuration: configuration,
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
        let publishers: [AnyPublisher<(offset: Int, details: SolanaTransactionHistoryDTO.TransactionDetails?), Error>] = signatures.enumerated().map { offset, signature in
            let target = SolanaTransactionHistoryTarget(configuration: configuration, request: .getTransaction(signature: signature))
            return networkProvider.requestPublisher(target)
                .filterSuccessfulStatusAndRedirectCodes()
                .map(JSONRPC.Response<SolanaTransactionHistoryDTO.TransactionDetails?, JSONRPC.APIError>.self)
                .tryMap { try $0.result.get() }
                .map { details in (offset: offset, details: details) }
                .eraseToAnyPublisher()
        }

        return Publishers.MergeMany(publishers)
            .collect()
            .map { indexedDetails in
                indexedDetails
                    .sorted { $0.offset < $1.offset }
                    .compactMap(\.details)
            }
            .eraseToAnyPublisher()
    }
}
