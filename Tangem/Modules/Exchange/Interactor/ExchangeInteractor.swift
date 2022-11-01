//
//  ExchangeTxInteractor.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk
import ExchangeSdk
import BigInt

class ExchangeTxInteractor {
    let walletModel: WalletModel
    let card: CardViewModel

    private var bag = Set<AnyCancellable>()

    init(walletModel: WalletModel, card: CardViewModel) {
        self.walletModel = walletModel
        self.card = card
    }

    func sendSwapTransaction(swapData: SwapData) -> AnyPublisher<(), Error> {
        let blockchain = walletModel.blockchainNetwork.blockchain
        let amount = Amount(with: blockchain, value: Decimal(string: swapData.tx.value) ?? 0)
        let gasPrice = Decimal(string: swapData.tx.gasPrice) ?? 0

        let gasValue = Decimal(swapData.tx.gas) * gasPrice / blockchain.decimalValue
        let gasAmount = Amount(with: blockchain, type: .coin, value: gasValue)

        do {
            var tx = try walletModel.walletManager.createTransaction(amount: amount,
                                                                     fee: gasAmount,
                                                                     destinationAddress: swapData.tx.to)
            let txData = Data(hexString: swapData.tx.data)
            tx.params = EthereumTransactionParams(data: txData)
            return walletModel.send(tx, signer: card.signer).eraseToAnyPublisher()
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
    }

    func sendApprovedTransaction(approveData: ApprovedTransactionData) -> AnyPublisher<(), Error> {
        let blockchain = walletModel.blockchainNetwork.blockchain

        let amount = Amount(with: blockchain, value: Decimal(string: approveData.value) ?? 0)

        let getFeePublisher = walletModel.walletManager.getFee(amount: amount, destination: approveData.to)

        return getFeePublisher
            .tryMap { [unowned self] fees -> Transaction in
                let fee: Amount
                if fees.count == 3 {
                    fee = fees[1]
                } else {
                    throw ExchangeError.failedToLoadFee
                }

                let decimalGasPrice = Decimal(string: approveData.gasPrice) ?? 0

                let gasValue = fee.value * decimalGasPrice / blockchain.decimalValue
                let gasAmount = Amount(with: blockchain,
                                       type: .coin,
                                       value: gasValue)
                do {
                    var tx = try self.walletModel.walletManager.createTransaction(amount: amount,
                                                                                  fee: gasAmount,
                                                                                  destinationAddress: approveData.to)
                    let txData = Data(hexString: approveData.data)
                    tx.params = EthereumTransactionParams(data: txData)

                    return tx
                } catch {
                    throw ExchangeError.failedToBuildTx
                }
            }
            .flatMap { [unowned self] tx in
                self.walletModel.send(tx, signer: self.card.signer)
                    .eraseToAnyPublisher()
            }.eraseToAnyPublisher()
    }
}

extension ExchangeTxInteractor {
    enum ExchangeError: Error {
        case failedToBuildTx
        case failedToLoadFee
    }
}
