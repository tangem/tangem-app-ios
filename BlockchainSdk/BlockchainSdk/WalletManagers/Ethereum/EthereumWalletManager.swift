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

class  EthereumWalletManager: WalletManager {
    var wallet: CurrentValueSubject<Wallet, Error>
    
    private var currencyWallet: CurrencyWallet
    private let cardId: String
    private let txBuilder: EthereumTransactionBuilder
    private let network: EthereumNetworkManager
    private var updateSubscription: AnyCancellable?
    private var sendSubscription: AnyCancellable?
    public var txCount: Int = -1
    public var pendingTxCount: Int = -1
    
    init(cardId: String, walletPublicKey: Data, walletConfig: WalletConfig, token: Token?, isTestnet: Bool) {
        self.cardId = cardId
        let blockchain: Blockchain = isTestnet ? .ethereumTestnet: .ethereum
        let address = blockchain.makeAddress(from: walletPublicKey)
        self.currencyWallet = CurrencyWallet(address: address, blockchain: blockchain, config: walletConfig)
        
        if let token = token {
            currencyWallet.add(amount: Amount(with: token))
        }
        network = EthereumNetworkManager()
        txBuilder = EthereumTransactionBuilder(walletPublicKey: walletPublicKey, isTestnet: isTestnet)
        wallet = CurrentValueSubject(currencyWallet)
    }
    
    func update() {
        updateSubscription = network.getInfo(address: currencyWallet.address, contractAddress: currencyWallet.balances[.token]!.address)
            .sink(receiveCompletion: {[unowned self] completion in
                if case let .failure(error) = completion {
                    self.wallet.send(completion: .failure(error))
                }
            }) { [unowned self] response in
                self.updateWallet(with: response)
        }
    }
    
    private func updateWallet(with response: EthereumResponse) {
        currencyWallet.balances[.coin]?.value = response.balance
        currencyWallet.balances[.token]?.value = response.tokenBalance
        txCount = response.txCount
        pendingTxCount = response.txCount
        if txCount == pendingTxCount {
            for  index in currencyWallet.pendingTransactions.indices {
                currencyWallet.pendingTransactions[index].status = .confirmed
            }
        } else {
            if currencyWallet.pendingTransactions.isEmpty {
                currencyWallet.pendingTransactions.append(Transaction(amount: Amount(with: .ethereum, address: ""), fee: nil, sourceAddress: "unknown", destinationAddress: currencyWallet.address))
            }
        }
        wallet.send(currencyWallet)
    }
}

extension EthereumWalletManager: TransactionSender {
    func send(_ transaction: Transaction, signer: TransactionSigner, completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let txForSign = txBuilder.buildForSign(transaction: transaction, nonce: txCount) else {
            completion(.failure(EthereumError.failedToBuildHash))
            return
        }
        
       sendSubscription =  signer.sign(hashes: [txForSign.hash], cardId: self.cardId)
            .tryMap {[unowned self] signResponse throws -> AnyPublisher<String, Error> in
                guard let tx = self.txBuilder.buildForSend(transaction: txForSign.transaction, hash: txForSign.hash, signature: signResponse.signature) else {
                    throw BitcoinError.failedToBuildTransaction
                }
                let txHexString = "0x\(tx.toHexString())"
                return self.network.send(transaction: txHexString)}
            .sink(receiveCompletion: { sendCompletion in
                if case let .failure(error) = sendCompletion {
                    completion(.failure(error))
                }
            }, receiveValue: {[unowned self] sendResponse in
                self.currencyWallet.add(transaction: transaction)
                self.wallet.send(self.currencyWallet)
                completion(.success(true))
            })
        
//        signer.sign(hashes: [txForSign.hash], cardId: self.cardId) { [unowned self] result in
//            switch result {
//            case .event(let response):
//                guard let tx = self.txBuilder.buildForSend(transaction: txForSign.transaction, hash: txForSign.hash, signature: response.signature) else {
//                    completion(.failure(BitcoinError.failedToBuildTransaction))
//                    return
//                }
//                let txHexString = "0x\(tx.toHexString())"
//                self.sendSubscription = self.network.send(transaction: txHexString)
//                    .sink(receiveCompletion: { sendCompletion in
//                        if case let .failure(error) = sendCompletion {
//                            completion(.failure(error))
//                        }
//                    }, receiveValue: {[unowned self] sendResponse in
//                        self.currencyWallet.add(transaction: transaction)
//                        self.wallet.send(self.currencyWallet)
//                        completion(.success(true))
//                    })
//
//            case .completion(let error):
//                if let error = error {
//                    completion(.failure(error))
//                }
//            }
//        }
    }
}

extension EthereumWalletManager: FeeProvider {
    func getFee(amount: Amount, source: String, destination: String, completion: @escaping (Result<[Amount], Error>) -> Void) {
        DispatchQueue.global().async {
            let web = web3(provider: InfuraProvider(Networks.Mainnet)!)
            
            guard let gasPrice = try? web.eth.getGasPrice() else {
                completion(.failure(EthereumError.failedToGetFee))
                return
            }
            
            let m = self.txBuilder.getGasLimit(for: amount)
            let decimalCount = self.currencyWallet.blockchain.decimalCount
            let minValue = gasPrice * m
            let min = Web3.Utils.formatToEthereumUnits(minValue, toUnits: .eth, decimals: decimalCount, decimalSeparator: ".", fallbackToScientific: false)!
            
            let normalValue = gasPrice * BigUInt(12) / BigUInt(10) * m
            let normal = Web3.Utils.formatToEthereumUnits(normalValue, toUnits: .eth, decimals: decimalCount, decimalSeparator: ".", fallbackToScientific: false)!
            
            let maxValue = gasPrice * BigUInt(15) / BigUInt(10) * m
            let max = Web3.Utils.formatToEthereumUnits(maxValue, toUnits: .eth, decimals: decimalCount, decimalSeparator: ".", fallbackToScientific: false)!
            
            guard let minDecimal = Decimal(string: min),
                let normalDecimal = Decimal(string: normal),
                let maxDecimal = Decimal(string: max) else {
                    completion(.failure(EthereumError.failedToGetFee))
                    return
            }
            
            let minAmount = Amount(with: self.currencyWallet.blockchain, address: self.currencyWallet.address, value: minDecimal)
            let normalAmount = Amount(with: self.currencyWallet.blockchain, address: self.currencyWallet.address, value: normalDecimal)
            let maxAmount = Amount(with: self.currencyWallet.blockchain, address: self.currencyWallet.address, value: maxDecimal)
            
            let fee = [minAmount, normalAmount, maxAmount]
            completion(.success(fee))
        }
    }
}

enum EthereumError: Error {
    case failedToGetFee
    case failedToBuildHash
}

extension EthereumTransaction {
    func encodeForSend(chainID: BigUInt? = nil) -> Data? {
        
        let encodeV = chainID == nil ? self.v :
            self.v - 27 + chainID! * 2 + 35
        
        let fields = [self.nonce, self.gasPrice, self.gasLimit, self.to.addressData, self.value, self.data, encodeV, self.r, self.s] as [AnyObject]
        return RLP.encode(fields)
    }
    
    init?(amount: BigUInt, fee: BigUInt, targetAddress: String, nonce: BigUInt, gasLimit: BigUInt = 21000, data: Data, v: BigUInt = 0, r: BigUInt = 0, s: BigUInt = 0) {
        let gasPrice = fee / gasLimit
        
        guard let ethAddress = EthereumAddress(targetAddress) else {
            return nil
        }
        
        self.init( nonce: nonce,
                   gasPrice: gasPrice,
                   gasLimit: gasLimit,
                   to: ethAddress,
                   value: amount,
                   data: data,
                   v: v,
                   r: r,
                   s: s)
    }
}

class EthereumTransactionBuilder {
    private let chainId: BigUInt = 1
    private let walletPublicKey: Data
    private let isTestnet: Bool
    
    init(walletPublicKey: Data, isTestnet: Bool) {
        self.walletPublicKey = walletPublicKey
        self.isTestnet = isTestnet
    }
    
    public func buildForSign(transaction: Transaction, nonce: Int) -> (hash: Data, transaction: EthereumTransaction)? {
        let nonceValue = BigUInt(nonce)
        
        guard let fee = transaction.fee,
            let amountDecimal = transaction.amount.value,
            let feeValue = Web3.Utils.parseToBigUInt("\(fee)", decimals: fee.decimals),
            let amountValue = Web3.Utils.parseToBigUInt("\(amountDecimal)", decimals: transaction.amount.decimals) else {
                return nil
        }
        
        let gasLimit = getGasLimit(for: transaction.amount)
        guard let data = getData(for: transaction.amount, targetAddress: transaction.destinationAddress) else {
            return nil
        }
        
        guard let transaction = EthereumTransaction(amount: transaction.amount.type == .coin ? amountValue : BigUInt.zero,
                                                    fee: feeValue,
                                                    targetAddress: transaction.destinationAddress,
                                                    nonce: nonceValue,
                                                    gasLimit: gasLimit,
                                                    data: data) else {
                                                        return nil
        }
        
        guard let hashForSign = transaction.hashForSignature(chainID: chainId) else {
            return nil
        }
        
        return (hashForSign, transaction)
    }
    
    public func buildForSend(transaction: EthereumTransaction, hash: Data, signature: Data) -> Data? {
        var transaction = transaction
        guard let unmarshalledSignature = CryptoUtils().unmarshal(secp256k1Signature: signature, hash: hash, publicKey: walletPublicKey) else {
            return nil
        }
        
        transaction.v = BigUInt(unmarshalledSignature.v)
        transaction.r = BigUInt(unmarshalledSignature.r)
        transaction.s = BigUInt(unmarshalledSignature.s)
        
        let encodedBytesToSend = transaction.encodeForSend(chainID: chainId)
        return encodedBytesToSend
    }
    
    fileprivate func getGasLimit(for amount: Amount) -> BigUInt {
        if amount.type == .coin {
            return 21000
        }
        
        if amount.currencySymbol == "DGX" {
            return 300000
        }
        
        return 60000
    }
    
    private func getData(for amount: Amount, targetAddress: String) -> Data? {
        if amount.type != .token {
            return Data()
        }
        
        guard let amountDecimal = amount.value,
            let amountValue = Web3.Utils.parseToBigUInt("\(amountDecimal)", decimals: amount.decimals) else {
                return nil
        }
        
        var amountString = String(amountValue, radix: 16).remove("0X")
        while amountString.count < 64 {
            amountString = "0" + amountString
        }
        
        let amountData = Data(hex: amountString)
        
        guard let addressData = EthereumAddress(targetAddress)?.addressData else {
            return nil
        }
        let prefixData = Data(hex: "a9059cbb000000000000000000000000")
        return prefixData + addressData + amountData
    }
}
