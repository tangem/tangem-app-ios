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
        guard let gasLoader = walletModel.walletManager as? EthereumGasLoader else {
            return Fail(error: ExchangeError.gasLoaderNotFind).eraseToAnyPublisher()
        }
        let blockchain = walletModel.blockchainNetwork.blockchain

        let amount = Amount(with: blockchain, value: Decimal(string: info.tx.value) ?? 0)

        return gasLoader.getGasLimit(amount: amount,
                                     destination: info.tx.to)
            .tryMap { [unowned self] gasPrice -> Transaction in
                let gasAmount = Amount(with: blockchain,
                                       type: .coin,
                                       value: Decimal(info.tx.gas * Int(gasPrice)) / blockchain.decimalValue)
                do {
                    var tx = try self.walletModel.walletManager.createTransaction(amount: amount,
                                                                                  fee: gasAmount,
                                                                                  destinationAddress: info.tx.to)
                    let txData = Data(hexString: info.tx.data)
                    tx.params = EthereumTransactionParams(data: txData)

                    return tx
                } catch {
                    throw ExchangeError.failedToBuildTx
                }
            }
            .flatMap({ [unowned self] tx in
                self.walletModel.send(tx, signer: self.card.signer)
                    .eraseToAnyPublisher()
            })
            .eraseToAnyPublisher()
    }
    
    func sendApproveTransaction(info: ApproveTransactionDTO) -> AnyPublisher<(), Error> {
        guard let gasLoader = walletModel.walletManager as? EthereumGasLoader else {
            return Fail(error: ExchangeError.gasLoaderNotFind).eraseToAnyPublisher()
        }
        let blockchain = walletModel.blockchainNetwork.blockchain

        let amount = Amount(with: blockchain, value: Decimal(string: info.value) ?? 0)
        
        let getFeePublisher = walletModel.walletManager.getFee(amount: amount, destination: info.to)
        
        return Publishers
            .CombineLatest(getFeePublisher, gasLoader.getGasPrice())
            .tryMap { [unowned self] (fees, gasPrice) -> Transaction in
                let fee: Amount
                if fees.count == 3 {
                    fee = fees[1]
                } else {
                    throw ExchangeError.loadFeeWasFail
                }
                
                let decimalGasPrice = Decimal(Int(gasPrice))
                
                let gasAmount = Amount(with: blockchain,
                                       type: .coin,
                                       value: fee.value * decimalGasPrice / blockchain.decimalValue)
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
