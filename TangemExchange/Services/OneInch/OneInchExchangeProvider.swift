//
//  OneInchExchangeProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class OneInchExchangeProvider {
    /// OneInch use this contractAddress for coins
    private let oneInchCoinContractAddress = "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"
    private let oneInchAPIProvider: OneInchAPIServicing

    private var bag = Set<AnyCancellable>()

    init(exchangeService: OneInchAPIServicing) {
        self.oneInchAPIProvider = exchangeService
    }
}

extension OneInchExchangeProvider: ExchangeProvider {
    // MARK: - Fetch data

    func fetchExchangeAmountAllowance(for currency: Currency, walletAddress: String) async throws -> Decimal {
        guard let contractAddress = currency.contractAddress else {
            throw Errors.noData
        }

        let blockchain = currency.blockchain

        let parameters = ApproveAllowanceParameters(
            tokenAddress: contractAddress,
            walletAddress: walletAddress
        )

        let allowanceResult = await oneInchAPIProvider.allowance(
            blockchain: blockchain,
            allowanceParameters: parameters
        )

        switch allowanceResult {
        case .success(let allowanceInfo):
            return Decimal(string: allowanceInfo.allowance) ?? 0
        case .failure(let error):
            throw error
        }
    }

    func fetchTxDataForSwap(items: ExchangeItems, walletAddress: String, amount: String, slippage: Int) async throws -> ExchangeSwapDataModel {
        let blockchain = items.source.blockchain
        let destination = items.destination
        let parameters = SwapParameters(
            fromTokenAddress: items.source.contractAddress ?? oneInchCoinContractAddress,
            toTokenAddress: destination.contractAddress ?? oneInchCoinContractAddress,
            amount: amount,
            fromAddress: walletAddress,
            slippage: slippage
        )

        let result = await oneInchAPIProvider.swap(blockchain: blockchain, parameters: parameters)

        switch result {
        case .success(let swapData):
            return ExchangeSwapDataModel(swapData: swapData)
        case .failure(let error):
            throw error
        }
    }

    // MARK: - Approve API

    func approveTxData(for currency: Currency) async throws -> ExchangeApprovedDataModel {
        guard let contractAddress = currency.contractAddress else {
            throw Errors.noData
        }

        let blockchain = currency.blockchain
        let parameters = ApproveTransactionParameters(tokenAddress: contractAddress, amount: .infinite)
        let txResponse = await oneInchAPIProvider.approveTransaction(
            blockchain: blockchain,
            approveTransactionParameters: parameters
        )

        switch txResponse {
        case .success(let approveTxData):
            return ExchangeApprovedDataModel(approveTxData: approveTxData)
        case .failure(let error):
            throw error
        }
    }

    func getSpenderAddress(for currency: Currency) async throws -> String {
        let blockchain = currency.blockchain
        let spender = await oneInchAPIProvider.spender(blockchain: blockchain)

        switch spender {
        case .success(let spender):
            return spender.address
        case .failure(let error):
            throw error
        }
    }
}
