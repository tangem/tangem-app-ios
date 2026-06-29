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

    private var paginationToken: String?
    private var hasReachedEnd = false
    private var tokenAccountAddress: String?
    private var tokenAccountAddressMint: String?

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
                "paginationToken": paginationToken ?? "-",
                "hasReachedEnd": hasReachedEnd,
                "tokenAccountAddress": tokenAccountAddress ?? "-",
            ]
        )
    }

    func reset() {
        paginationToken = nil
        hasReachedEnd = false
        tokenAccountAddress = nil
        tokenAccountAddressMint = nil
        mapper.reset()
    }

    func loadTransactionHistory(request: TransactionHistory.Request) -> AnyPublisher<TransactionHistory.Response, Error> {
        guard case .address(let address) = request.key else {
            return .anyFail(error: TransactionHistory.ProviderError.requestKeyNotSupported)
        }

        // Solana does not support fee resource type for transaction history.
        // All fees are paid in SOL.
        if case .feeResource = request.amountType {
            hasReachedEnd = true
            return .justWithError(output: .init(records: []))
        }

        return resolveQueryAddress(walletAddress: address, amountType: request.amountType)
            .withWeakCaptureOf(self)
            .flatMap { provider, queryAddress -> AnyPublisher<[SolanaTransactionHistoryDTO.TransactionDetails], Error> in
                guard let queryAddress else {
                    provider.hasReachedEnd = true
                    provider.paginationToken = nil
                    return .justWithError(output: [])
                }

                return provider.fetchTransactions(
                    address: queryAddress,
                    limit: request.limit
                )
            }
            .withWeakCaptureOf(self)
            .tryMap { provider, transactions -> TransactionHistory.Response in
                let records = try provider.mapper.mapToTransactionRecords(
                    transactions,
                    walletAddress: address,
                    amountType: request.amountType
                )

                // Ignore Solana 0 amount txs filtering.
                // As Solana has different balance changes calculations that doesn't include fee/gas.
                // We need to show all of them.

                return .init(records: records)
            }
            .eraseToAnyPublisher()
    }
}

private extension SolanaTransactionHistoryProvider {
    func resolveQueryAddress(walletAddress: String, amountType: Amount.AmountType) -> AnyPublisher<String?, Error> {
        guard case .token(let token) = amountType else {
            return .justWithError(output: walletAddress)
        }

        if tokenAccountAddressMint == token.contractAddress, let tokenAccountAddress {
            return .justWithError(output: tokenAccountAddress)
        }

        let target = SolanaTransactionHistoryTarget(
            configuration: configuration,
            request: .getTokenAccountsByOwner(
                owner: walletAddress,
                mint: token.contractAddress
            )
        )

        return networkProvider.requestPublisher(target)
            .filterSuccessfulStatusAndRedirectCodes()
            .map(JSONRPC.Response<SolanaTransactionHistoryDTO.TokenAccountsByOwner, JSONRPC.APIError>.self)
            .tryMap { [weak self] response in
                let tokenAccountAddress = try response.result.get().value.first?.pubkey
                self?.tokenAccountAddress = tokenAccountAddress
                self?.tokenAccountAddressMint = token.contractAddress
                return tokenAccountAddress
            }
            .eraseToAnyPublisher()
    }

    func fetchTransactions(
        address: String,
        limit: Int
    ) -> AnyPublisher<[SolanaTransactionHistoryDTO.TransactionDetails], Error> {
        let target = SolanaTransactionHistoryTarget(
            configuration: configuration,
            request: .getTransactionsForAddress(
                address: address,
                limit: limit,
                paginationToken: paginationToken
            )
        )

        return networkProvider.requestPublisher(target)
            .filterSuccessfulStatusAndRedirectCodes()
            .map(JSONRPC.Response<SolanaTransactionHistoryDTO.TransactionsForAddress, JSONRPC.APIError>.self)
            .tryMap { [weak self] response -> [SolanaTransactionHistoryDTO.TransactionDetails] in
                guard let self else {
                    throw BlockchainSdkError.empty
                }

                let result = try response.result.get()
                paginationToken = result.paginationToken
                hasReachedEnd = result.paginationToken == nil

                return result.data
            }
            .eraseToAnyPublisher()
    }
}
