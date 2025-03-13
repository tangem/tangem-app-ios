//
//  KaspaTransactionHistoryProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemNetworkUtils

final class KaspaTransactionHistoryProvider: TransactionHistoryProvider {
    private let networkProvider: NetworkProvider<KaspaTransactionHistoryTarget>
    private let mapper: KaspaTransactionHistoryMapper

    private var page: TransactionHistoryIndexPage?
    private var hasReachedEnd = false

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()

    init(
        networkConfiguration: NetworkProviderConfiguration,
        mapper: KaspaTransactionHistoryMapper
    ) {
        networkProvider = .init(configuration: networkConfiguration)
        self.mapper = mapper
    }

    var canFetchHistory: Bool {
        !hasReachedEnd
    }

    // [REDACTED_TODO_COMMENT]
    func loadTransactionHistory(request: TransactionHistory.Request) -> AnyPublisher<TransactionHistory.Response, any Error> {
        // if indexing is created, load the next page
        let requestPage: Int = if let page {
            page.number + 1
        } else {
            0
        }

        let limit = min(request.limit, Constants.maxPageSize)

        let target = KaspaTransactionHistoryTarget(
            type: .getCoinTransactionHistory(
                address: request.address,
                page: requestPage,
                limit: limit
            )
        )
        return networkProvider.requestPublisher(target)
            .filterSuccessfulStatusAndRedirectCodes()
            .map([KaspaTransactionHistoryResponse.Transaction].self, using: decoder)
            .eraseError()
            .handleEvents(receiveOutput: { [weak self] transactions in
                self?.page = TransactionHistoryIndexPage(number: requestPage)
                self?.hasReachedEnd = transactions.count < limit
            })
            .withWeakCaptureOf(self)
            .tryMap { historyProvider, result in
                let transactionRecords = try historyProvider
                    .mapper
                    .mapToTransactionRecords(result, walletAddress: request.address, amountType: request.amountType)
                    .filter { record in
                        historyProvider.shouldBeIncludedInHistory(
                            amountType: request.amountType,
                            record: record
                        )
                    }
                return TransactionHistory.Response(records: transactionRecords)
            }
            .eraseToAnyPublisher()
    }

    func reset() {
        page = nil
        hasReachedEnd = false
    }
}

extension KaspaTransactionHistoryProvider {
    enum Constants {
        static let maxPageSize: Int = 50 // kaspa api limit
    }
}
