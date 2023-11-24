//
//  OneInchSwappingProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class OneInchSwappingProvider {
    /// OneInch use this contractAddress for coins
    private let oneInchCoinContractAddress = "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"
    private let defaultSlippage = 1
    private let oneInchAPIProvider: OneInchAPIServicing

    private var bag = Set<AnyCancellable>()

    init(swappingService: OneInchAPIServicing) {
        oneInchAPIProvider = swappingService
    }
}

extension OneInchSwappingProvider: SwappingProvider {
    // MARK: - Fetch data

    func fetchSwappingData(items: SwappingItems, walletAddress: String, amount: String, referrer: SwappingReferrerAccount?) async throws -> SwappingDataModel {
        let destination = items.destination
        let parameters = SwappingParameters(
            src: items.source.contractAddress ?? oneInchCoinContractAddress,
            dst: destination?.contractAddress ?? oneInchCoinContractAddress,
            amount: amount,
            from: walletAddress,
            slippage: defaultSlippage,
            referrer: referrer?.address,
            fee: referrer?.fee.description
        )

        let result = await oneInchAPIProvider.swap(blockchain: items.source.blockchain, parameters: parameters)

        switch result {
        case .success(let swappingData):
            return try SwappingDataModel(sourceAmount: amount, swappingData: swappingData)
        case .failure(let error):
            throw error
        }
    }

    func fetchQuote(items: SwappingItems, amount: String, referrer: SwappingReferrerAccount?) async throws -> SwappingQuoteDataModel {
        let parameters = QuoteParameters(
            src: items.source.contractAddress ?? oneInchCoinContractAddress,
            dst: items.destination?.contractAddress ?? oneInchCoinContractAddress,
            amount: amount,
            fee: referrer?.fee.description
        )

        let result = await oneInchAPIProvider.quote(blockchain: items.source.blockchain, parameters: parameters)

        switch result {
        case .success(let quoteData):
            return try SwappingQuoteDataModel(sourceAmount: amount, quoteData: quoteData)
        case .failure(let error):
            throw error
        }
    }

    func fetchSpenderAddress(for blockchain: SwappingBlockchain) async throws -> String {
        let spender = await oneInchAPIProvider.spender(blockchain: blockchain)

        switch spender {
        case .success(let spender):
            return spender.address
        case .failure(let error):
            throw error
        }
    }
}
