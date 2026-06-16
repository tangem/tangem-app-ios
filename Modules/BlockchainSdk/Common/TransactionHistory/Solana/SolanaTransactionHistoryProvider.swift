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
            ]
        )
    }

    func reset() {
        paginationToken = nil
        hasReachedEnd = false
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

        return fetchTransactions(
            address: address,
            limit: request.limit,
            tokenAccountsFilter: tokenAccountsFilter(amountType: request.amountType)
        )
        .tryMap { [weak self] transactions -> TransactionHistory.Response in
            guard let self else {
                throw BlockchainSdkError.empty
            }

            let records = try mapper.mapToTransactionRecords(
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
    func tokenAccountsFilter(amountType: Amount.AmountType) -> SolanaTransactionHistoryTarget.Request.TokenAccountsFilter {
        switch amountType {
        case .token:
            return .balanceChanged
        case .coin, .reserve, .feeResource:
            return .default
        }
    }

    func fetchTransactions(
        address: String,
        limit: Int,
        tokenAccountsFilter: SolanaTransactionHistoryTarget.Request.TokenAccountsFilter
    ) -> AnyPublisher<[SolanaTransactionHistoryDTO.TransactionDetails], Error> {
        let target = SolanaTransactionHistoryTarget(
            configuration: configuration,
            request: .getTransactionsForAddress(
                address: address,
                limit: limit,
                paginationToken: paginationToken,
                tokenAccountsFilter: tokenAccountsFilter
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
