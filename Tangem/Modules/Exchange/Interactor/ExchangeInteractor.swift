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
import Exchanger
import BigInt

class ExchangeTxInteractor {
    let walletModel: WalletModel
    let card: CardViewModel

    private var bag = Set<AnyCancellable>()

    init(walletModel: WalletModel, card: CardViewModel) {
        self.walletModel = walletModel
        self.card = card
    }

    func sendSwapTransaction(info: SwapDTO) -> AnyPublisher<(), Error> {
        let blockchain = walletModel.blockchainNetwork.blockchain
        let amount = Amount(with: blockchain, value: Decimal(string: info.tx.value) ?? 0)
        let gasPrice = Decimal(string: info.tx.gasPrice) ?? 0

        let gasValue = Decimal(info.tx.gas) * gasPrice / blockchain.decimalValue
        let gasAmount = Amount(with: blockchain, type: .coin, value: gasValue)

        do {
            var tx = try walletModel.walletManager.createTransaction(amount: amount,
                                                                     fee: gasAmount,
                                                                     destinationAddress: info.tx.to)
            let txData = Data(hexString: info.tx.data)
            tx.params = EthereumTransactionParams(data: txData)
            return walletModel.send(tx, signer: card.signer).eraseToAnyPublisher()
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
    }

    func sendApproveTransaction(info: ApproveTransactionDTO) -> AnyPublisher<(), Error> {
        let blockchain = walletModel.blockchainNetwork.blockchain

        let amount = Amount(with: blockchain, value: Decimal(string: info.value) ?? 0)

        let getFeePublisher = walletModel.walletManager.getFee(amount: amount, destination: info.to)

        return getFeePublisher
            .tryMap { [unowned self] fees -> Transaction in
                let fee: Amount
                if fees.count == 3 {
                    fee = fees[1]
                } else {
                    throw ExchangeError.loadFeeWasFail
                }

                let decimalGasPrice = Decimal(string: info.gasPrice) ?? 0

                let gasValue = fee.value * decimalGasPrice / blockchain.decimalValue
                let gasAmount = Amount(with: blockchain,
                                       type: .coin,
                                       value: gasValue)
                do {
                    var tx = try self.walletModel.walletManager.createTransaction(amount: amount,
                                                                                  fee: gasAmount,
                                                                                  destinationAddress: info.to)
                    let txData = Data(hexString: info.data)
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
        case gasLoaderNotFind
        case failedToBuildTx
        case loadFeeWasFail
    }
}
