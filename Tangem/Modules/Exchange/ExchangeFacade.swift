//
//  ExchangeFacade.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk
import ExchangeSdk

class ExchangeFacade {
    @Injected(\.exchangeOneInchService) private var exchangeService: ExchangeServiceProtocol

    let exchangeManager: ExchangeManager
    let signer: TangemSigner

    private var bag = Set<AnyCancellable>()

    init(exchangeManager: ExchangeManager, signer: TangemSigner) {
        self.exchangeManager = exchangeManager
        self.signer = signer
    }

    // MARK: - Sending API

    func sendSwapTransaction(swapData: SwapData, sourceItem: ExchangeItem) async throws {
        try await withCheckedThrowingContinuation { continuation in
            let decimal = Decimal(string: swapData.tx.value) ?? 0
            let amount = sourceItem.currency.createAmount(with: decimal)

            do {
                let gasPrice = Decimal(string: swapData.tx.gasPrice) ?? 0
                let gasValue = Decimal(swapData.tx.gas) * gasPrice / exchangeManager.blockchainNetwork.blockchain.decimalValue

                let txData = Data(hexString: swapData.tx.data)

                let tx = try buildTransaction(gas: gasValue, destinationAddress: swapData.tx.to, txData: txData, amount: amount)
                Task {
                    try await exchangeManager.send(tx, signer: signer)
                    continuation.resume()
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    func sendApprovedTransaction(approveData: ApprovedTransactionData, for item: ExchangeItem) async throws {
        try await withCheckedThrowingContinuation { continuation in
            let amount = item.currency.createAmount(with: 0)

            Task {
                let blockchain = exchangeManager.blockchainNetwork.blockchain
                do {
                    let fees = try await exchangeManager.getFee(amount: amount, destination: approveData.to)
                    let fee: Amount = fees[1]
                    let decimalGasPrice = Decimal(string: approveData.gasPrice) ?? 0
                    let gasValue = fee.value * decimalGasPrice / blockchain.decimalValue
                    let txData = Data(hexString: approveData.data)

                    let tx = try buildTransaction(gas: gasValue, destinationAddress: approveData.to, txData: txData, amount: amount)

                    try await exchangeManager.send(tx, signer: signer)

                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - Swap API

    func fetchSwapData(parameters: SwapParameters, items: ExchangeItems) async throws -> SwapData {
        try await withCheckedThrowingContinuation({ continuation in
            Task {
                let result = await exchangeService.swap(blockchain: ExchangeBlockchain.convert(from: exchangeManager.blockchainNetwork), parameters: parameters)

                switch result {
                case .success(let swapData):
                    continuation.resume(returning: swapData)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        })
    }

    // MARK: - Approve API

    func fetchApprove(for item: ExchangeItem) async {
        guard !item.isLockedForChange else { return }

        Task {
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
    }

    func approveTxData(for item: ExchangeItem) async throws -> ApprovedTransactionData {
        return try await withCheckedThrowingContinuation({ continuation in
            Task {
                let parameters = ApproveTransactionParameters(tokenAddress: item.tokenAddress, amount: .infinite)
                let txResponse = await exchangeService.approveTransaction(blockchain: ExchangeBlockchain.convert(from: exchangeManager.blockchainNetwork), approveTransactionParameters: parameters)

                switch txResponse {
                case .success(let approveTxData):
                    continuation.resume(returning: approveTxData)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        })
    }

    func getSpender() async throws -> String {
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

extension ExchangeFacade {
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

