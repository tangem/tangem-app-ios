//
//  ExchangeOneInchProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk
import ExchangeSdk

class ExchangeOneInchProvider {
    /// OneInch use this contractAddress for coins
    private let oneInchCoinContractAddress = "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"
    
    private let exchangeService: ExchangeServiceProtocol
    private let blockchainProvider: BlockchainProvider
    
    private var bag = Set<AnyCancellable>()
    
    init(blockchainProvider: BlockchainProvider, exchangeService: ExchangeServiceProtocol) {
        self.blockchainProvider = blockchainProvider
        self.exchangeService = exchangeService
    }
}

extension ExchangeOneInchProvider: ExchangeProvider {
    // MARK: - Fetch data
    
    func fetchExchangeAmountLimit(for currency: Currency) async throws -> Decimal {
        guard currency.isToken,
              let contractAddress = currency.contractAddress,
              let chainId = currency.chainId else { return }

        let parameters = ApproveAllowanceParameters(
            tokenAddress: contractAddress,
            walletAddress: exchangeManager.walletAddress
        )

        let allowanceResult = await exchangeService.allowance(
            blockchain: .exchangeBlockchain(from: chainId),
            allowanceParameters: parameters
        )

        switch allowanceResult {
        case .success(let allowanceInfo):
            return Decimal(string: allowanceInfo.allowance) ?? 0
        case .failure(let error):
            throw error
        }
    }
    
    func fetchTxDataForSwap(items: ExchangeItems, amount: String, slippage: Int) async throws -> ExchangeSwapDataModel {
        let parameters = SwapParameters(fromTokenAddress: items.source.contractAddress ?? oneInchCoinContractAddress,
                                        toTokenAddress: items.destination.contractAddress ?? oneInchCoinContractAddress,
                                        amount: amount,
                                        fromAddress: exchangeManager.walletAddress,
                                        slippage: slippage)

        let result = await exchangeService.swap(blockchain: .exchangeBlockchain(from: items.source.chainId),
                                                parameters: parameters)

        switch result {
        case .success(let swapData):
            return ExchangeSwapDataModel(swapData: swapData)
        case .failure(let error):
            throw error
        }
    }
    
    // MARK: - Sending API
    
    func sendSwapTransaction(_ info: SwapTransactionInfo, gasValue: Decimal, gasPrice: Decimal) async throws {
        let gas = gas(from: gasValue, price: gasPrice, decimalCount: info.currency.decimalValue)

        let tx = buildTransaction(for: info.currency, fee: gas)
        return try await blockchainProvider.signAndSend(tx)
    }

    func submitPermissionForToken(_ info: SwapTransactionInfo, gasPrice: Decimal) async throws {
        let fees = try await blockchainProvider.getFee(currency: currency, amount: amount, destination: destination)
        let gasValue: Decimal = fees[1]
        
        let gas = gas(from: gasValue, price: gasPrice, decimalCount: currency.decimalValue)
        let tx = buildTransaction(for: info.currency, fee: gas)
        
        return try await blockchainProvider.signAndSend(tx)
    }

    // MARK: - Approve API
    
    func approveTxData(for item: Currency) async throws -> ExchangeApprovedDataModel {
        let parameters = ApproveTransactionParameters(tokenAddress: currency.contractAddress, amount: .infinite)
        let txResponse = await exchangeService.approveTransaction(blockchain: ExchangeBlockchain.convert(from: blockchainNetwork),
                                                                  approveTransactionParameters: parameters)
    }

    func approveTxData(for item: ExchangeItem) async throws -> ExchangeApprovedDataModel {
        let parameters = ApproveTransactionParameters(tokenAddress: item.currency.contractAddress, amount: .infinite)
        

        switch txResponse {
        case .success(let approveTxData):
            let model = ExchangeApprovedDataModel(approveTxData: approveTxData)
            return model
        case .failure(let error):
            throw error
        }
    }

    func getSpenderAddress() async throws -> String {
        let blockchain = ExchangeBlockchain.convert(from: blockchainNetwork)

        let spender = await exchangeService.spender(blockchain: blockchain)

        switch spender {
        case .success(let spender):
            return spender.address
        case .failure(let error):
            throw error
        }
    }
}

// MARK: - Private

private extension ExchangeOneInchProvider {
    func gas(from value: Decimal, price: Decimal, decimalCount: Decimal) -> Decimal {
        value * price / decimalValue
    }
    
    func buildTransaction(for info: SwapTransactionInfo, fee: Decimal) throws -> Transaction {
        let info = TransactionInfo(currency: info.currency, amount: info.amount, fee: fee, destination: info.destination)
        let tx = try blockchainProvider.createTransaction(for: info)
        tx.params = EthereumTransactionParams(data: oneInchTxData)

        return tx
        
        
//        let blockchain = blockchainNetwork.blockchain
//        let gasAmount = Amount(with: blockchain, type: .coin, value: gas)
//
//        var tx = try exchangeManager.createTransaction(for: currency,
//                                                       fee: gas,
//                                                       destinationAddress: destinationAddress)
//        tx.params = EthereumTransactionParams(data: txData) // For what?

//        return tx
    }
}
