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

    func fetchAmountAllowance(for currency: Currency, walletAddress: String) async throws -> Decimal {
        guard let contractAddress = currency.contractAddress else {
            throw Errors.noData
        }

        let parameters = ApproveAllowanceParameters(
            tokenAddress: contractAddress,
            walletAddress: walletAddress
        )

        let allowanceResult = await oneInchAPIProvider.allowance(
            blockchain: currency.blockchain,
            allowanceParameters: parameters
        )

        switch allowanceResult {
        case .success(let allowanceInfo):
            return Decimal(string: allowanceInfo.allowance) ?? 0
        case .failure(let error):
            throw error
        }
    }

    func fetchSwappingData(items: SwappingItems, walletAddress: String, amount: String, referrer: SwappingReferrerAccount?) async throws -> SwappingDataModel {
        let destination = items.destination
        let parameters = SwappingParameters(
            fromTokenAddress: items.source.contractAddress ?? oneInchCoinContractAddress,
            toTokenAddress: destination?.contractAddress ?? oneInchCoinContractAddress,
            amount: amount,
            fromAddress: walletAddress,
            slippage: defaultSlippage,
            referrerAddress: referrer?.address,
            fee: referrer?.fee.description
        )

        let result = await oneInchAPIProvider.swap(blockchain: items.source.blockchain, parameters: parameters)

        switch result {
        case .success(let swappingData):
            return try SwappingDataModel(swappingData: swappingData)
        case .failure(let error):
            throw error
        }
    }

    func fetchQuote(items: SwappingItems, amount: String, referrer: SwappingReferrerAccount?) async throws -> SwappingQuoteDataModel {
        let parameters = QuoteParameters(
            fromTokenAddress: items.source.contractAddress ?? oneInchCoinContractAddress,
            toTokenAddress: items.destination?.contractAddress ?? oneInchCoinContractAddress,
            amount: amount,
            fee: referrer?.fee.description
        )

        let result = await oneInchAPIProvider.quote(blockchain: items.source.blockchain, parameters: parameters)

        switch result {
        case .success(let quoteData):
            return try SwappingQuoteDataModel(quoteData: quoteData)
        case .failure(let error):
            throw error
        }
    }

    // MARK: - Approve API

    func fetchApproveSwappingData(for currency: Currency) async throws -> SwappingApprovedDataModel {
        guard let contractAddress = currency.contractAddress else {
            throw Errors.noData
        }

        let parameters = ApproveTransactionParameters(tokenAddress: contractAddress, amount: .infinite)
        let txResponse = await oneInchAPIProvider.approveTransaction(
            blockchain: currency.blockchain,
            approveTransactionParameters: parameters
        )

        switch txResponse {
        case .success(let approveTxData):
            return try SwappingApprovedDataModel(approveTxData: approveTxData)
        case .failure(let error):
            throw error
        }
    }

    func fetchSpenderAddress(for currency: Currency) async throws -> String {
        let spender = await oneInchAPIProvider.spender(blockchain: currency.blockchain)

        switch spender {
        case .success(let spender):
            return spender.address
        case .failure(let error):
            throw error
        }
    }
}
