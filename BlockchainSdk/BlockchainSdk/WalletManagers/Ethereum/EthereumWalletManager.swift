//
//  EthereumWalletManager.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import BigInt
import web3swift
import Combine
import RxSwift
import TangemSdk

class EthereumWalletManager: WalletManager<CurrencyWallet> {
    var txBuilder: EthereumTransactionBuilder!
    var network: EthereumNetworkManager!
    var txCount: Int = -1
    var pendingTxCount: Int = -1

    override func update() {
        requestDisposable = network
            .getInfo(address: wallet.address, contractAddress: wallet.token?.contractAddress)
            .subscribe(onSuccess: {[unowned self] response in
                self.updateWallet(with: response)
                }, onError: {[unowned self] error in
                    self.onError.onNext(error)
            })
    }
    
    private func updateWallet(with response: EthereumResponse) {
        wallet.add(coinValue: response.balance)
        if let tokenBalance = response.tokenBalance {
            wallet.add(tokenValue: tokenBalance)
        }
        txCount = response.txCount
        pendingTxCount = response.txCount
        if txCount == pendingTxCount {
            for  index in wallet.pendingTransactions.indices {
                wallet.pendingTransactions[index].status = .confirmed
            }
        } else {
            if wallet.pendingTransactions.isEmpty {
                wallet.addIncomingTransaction()
            }
        }
          walletDidUpdate()
    }
}

@available(iOS 13.0, *)
extension EthereumWalletManager: TransactionSender {
    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<Bool, Error> {
        guard let txForSign = txBuilder.buildForSign(transaction: transaction, nonce: txCount) else {
            return Fail(error: EthereumError.failedToBuildHash).eraseToAnyPublisher()
        }
        
        return signer.sign(hashes: [txForSign.hash], cardId: self.cardId)
            .tryMap {[unowned self] signResponse throws -> AnyPublisher<String, Error> in
                guard let tx = self.txBuilder.buildForSend(transaction: txForSign.transaction, hash: txForSign.hash, signature: signResponse.signature) else {
                    throw BitcoinError.failedToBuildTransaction
                }
                let txHexString = "0x\(tx.toHexString())"
                return self.network.send(transaction: txHexString)}
            .map {[unowned self] response in
                self.wallet.add(transaction: transaction)
                self.walletDidUpdate()
                return true
        }
    .eraseToAnyPublisher()
    }
    
    func getFee(amount: Amount, source: String, destination: String) -> AnyPublisher<[Amount],Error> {
        return network.getGasPrice()
            .tryMap { [unowned self] gasPrice throws -> [Amount] in
                let m = self.txBuilder.getGasLimit(for: amount)
                let decimalCount = self.wallet.blockchain.decimalCount
                let minValue = gasPrice * m
                let min = Web3.Utils.formatToEthereumUnits(minValue, toUnits: .eth, decimals: decimalCount, decimalSeparator: ".", fallbackToScientific: false)!
                
                let normalValue = gasPrice * BigUInt(12) / BigUInt(10) * m
                let normal = Web3.Utils.formatToEthereumUnits(normalValue, toUnits: .eth, decimals: decimalCount, decimalSeparator: ".", fallbackToScientific: false)!
                
                let maxValue = gasPrice * BigUInt(15) / BigUInt(10) * m
                let max = Web3.Utils.formatToEthereumUnits(maxValue, toUnits: .eth, decimals: decimalCount, decimalSeparator: ".", fallbackToScientific: false)!
                
                guard let minDecimal = Decimal(string: min),
                    let normalDecimal = Decimal(string: normal),
                    let maxDecimal = Decimal(string: max) else {
                        throw EthereumError.failedToGetFee
                }
                
                let minAmount = Amount(with: self.wallet.blockchain, address: self.wallet.address, value: minDecimal)
                let normalAmount = Amount(with: self.wallet.blockchain, address: self.wallet.address, value: normalDecimal)
                let maxAmount = Amount(with: self.wallet.blockchain, address: self.wallet.address, value: maxDecimal)
                
                return [minAmount, normalAmount, maxAmount]
        }
        .eraseToAnyPublisher()
    }
}

enum EthereumError: Error {
    case failedToGetFee
    case failedToBuildHash
}



extension EthereumWalletManager: ThenProcessable { }
