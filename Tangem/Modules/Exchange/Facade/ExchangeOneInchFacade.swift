//
//  ExchangeOneInchFacade.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk
import ExchangeSdk

class ExchangeOneInchFacade: ExchangeFacade {
    @Injected(\.exchangeOneInchService) private var exchangeService: ExchangeServiceProtocol

    let exchangeManager: ExchangeManager
    let signer: TangemSigner

    private var bag = Set<AnyCancellable>()

    init(exchangeManager: ExchangeManager, signer: TangemSigner) {
        self.exchangeManager = exchangeManager
        self.signer = signer
    }

    // MARK: - Sending API

    func sendSwapTransaction(destinationAddress: String,
                             amount: String,
                             gas: String,
                             gasPrice: String,
                             txData: Data,
                             sourceItem: ExchangeItem) async throws {
        let decimal = Decimal(string: amount) ?? 0
        let amount = sourceItem.currency.createAmount(with: decimal)

        do {
            let gasPrice = Decimal(string: gasPrice) ?? 0
            let gasValue = Decimal(string: gas) ?? 0 * gasPrice / exchangeManager.blockchainNetwork.blockchain.decimalValue

            let tx = try buildTransaction(gas: gasValue, destinationAddress: destinationAddress, txData: txData, amount: amount)
            try await exchangeManager.send(tx, signer: signer)

            return
        } catch {
            throw error
        }
    }

    func submitPermissionForToken(destinationAddress: String,
                                  gasPrice: String,
                                  txData: Data,
                                  for item: ExchangeItem) async throws {
        let amount = item.currency.createAmount(with: 0)

        let blockchain = exchangeManager.blockchainNetwork.blockchain
        do {
            let fees = try await exchangeManager.getFee(amount: amount, destination: destinationAddress)
            let fee: Amount = fees[1]
            let decimalGasPrice = Decimal(string: gasPrice) ?? 0
            let gasValue = fee.value * decimalGasPrice / blockchain.decimalValue

            let tx = try buildTransaction(gas: gasValue,
                                          destinationAddress: destinationAddress,
                                          txData: txData,
                                          amount: amount)

            try await exchangeManager.send(tx, signer: signer)

            return
        } catch {
            throw error
        }
    }

    // MARK: - Swap API

    func fetchTxDataForSwap(amount: String,
                            slippage: Int,
                            items: ExchangeItems) async throws -> ExchangeSwapDataModel {

        let parameters = SwapParameters(fromTokenAddress: items.sourceItem.tokenAddress,
                                        toTokenAddress: items.destinationItem.tokenAddress,
                                        amount: amount,
                                        fromAddress: exchangeManager.walletAddress,
                                        slippage: 1)

        let result = await exchangeService.swap(blockchain: ExchangeBlockchain.convert(from: exchangeManager.blockchainNetwork),
                                                parameters: parameters)

        switch result {
        case .success(let swapData):
            let model = ExchangeSwapDataModel(gas: swapData.tx.gas,
                                              gasPrice: swapData.tx.gasPrice,
                                              destinationAddress: swapData.tx.to,
                                              sourceAddress: swapData.tx.from,
                                              txData: Data(hexString: swapData.tx.data),
                                              fromTokenAmount: swapData.fromTokenAmount,
                                              toTokenAmount: swapData.toTokenAmount,
                                              fromTokenAddress: swapData.fromToken.address,
                                              toTokenAddress: swapData.toToken.address)
            return model
        case .failure(let error):
            throw error
        }
    }

    // MARK: - Approve API

    func fetchExchangeAmountLimit(for item: ExchangeItem) async {
        guard case .token = item.currency.type else { return }

        let contractAddress: String = item.tokenAddress
        let parameters = ApproveAllowanceParameters(tokenAddress: contractAddress, walletAddress: exchangeManager.walletAddress)

        let allowanceResult = await exchangeService.allowance(blockchain: ExchangeBlockchain.convert(from: exchangeManager.blockchainNetwork),
                                                              allowanceParameters: parameters)

        switch allowanceResult {
        case .success(let allowanceInfo):
            item.updateAllowance(Decimal(string: allowanceInfo.allowance) ?? 0)
        case .failure(let error):
            print(error.localizedDescription)
        }
    }

    func approveTxData(for item: ExchangeItem) async throws -> ExchangeApprovedDataModel {
        let parameters = ApproveTransactionParameters(tokenAddress: item.tokenAddress, amount: .infinite)
        let txResponse = await exchangeService.approveTransaction(blockchain: ExchangeBlockchain.convert(from: exchangeManager.blockchainNetwork),
                                                                  approveTransactionParameters: parameters)

        switch txResponse {
        case .success(let approveTxData):
            let model = ExchangeApprovedDataModel(data: Data(hexString: approveTxData.data),
                                                  gasPrice: approveTxData.gasPrice,
                                                  to: approveTxData.to,
                                                  value: approveTxData.value)
            return model
        case .failure(let error):
            throw error
        }
    }

    func getSpenderAddress() async throws -> String {
        let blockchain = ExchangeBlockchain.convert(from: exchangeManager.blockchainNetwork)

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

extension ExchangeOneInchFacade {
    private func buildTransaction(gas: Decimal, destinationAddress: String, txData: Data, amount: Amount) throws -> Transaction {
        let blockchain = exchangeManager.blockchainNetwork.blockchain
        let gasAmount = Amount(with: blockchain, type: .coin, value: gas)

        do {
            var tx = try exchangeManager.createTransaction(amount: amount,
                                                           fee: gasAmount,
                                                           destinationAddress: destinationAddress)
            tx.params = EthereumTransactionParams(data: txData)

            return tx
        } catch {
            throw error
        }
    }
}
