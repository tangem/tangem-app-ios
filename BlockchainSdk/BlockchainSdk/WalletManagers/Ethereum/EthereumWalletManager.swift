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

class  EthereumWalletManager: WalletManager {
    var wallet: Wallet { return _wallet }
    
    private var _wallet: CurrencyWallet
    private let cardId: String
    private let txBuilder: EthereumTransactionBuilder
    
    init(cardId: String, walletPublicKey: Data, walletConfig: WalletConfig, asset: Token?, isTestnet: Bool) {
        self.cardId = cardId
        let blockchain: Blockchain = isTestnet ? .ethereumTestnet: .ethereum
        let address = blockchain.makeAddress(from: walletPublicKey)
        self._wallet = CurrencyWallet(address: address, blockchain: blockchain, config: walletConfig)
        
        if let asset = asset {
            let assetAmount = Amount(type: .token, currencySymbol: asset.symbol, value: nil, address: asset.contractAddress, decimals: asset.decimals)
            _wallet.addAmount(assetAmount)
        }
        
        txBuilder = EthereumTransactionBuilder(walletPublicKey: walletPublicKey, isTestnet: isTestnet)
    }
    
    func update() {
        
    }
}

extension EthereumWalletManager: TransactionSender {
    func send(_ transaction: Transaction, signer: TransactionSigner, completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let txForSign = txBuilder.buildForSign(transaction: transaction) else {
            completion(.failure(EthereumError.failedToBuildHash))
            return
        }
        
        signer.sign(hashes: [txForSign.hash], cardId: self.cardId) {[weak self] result in
            switch result {
            case .event(let response):
                guard let self = self else { return }
                
                guard let tx = self.txBuilder.buildForSend(transaction: txForSign.transaction, hash: txForSign.hash, signature: response.signature) else {
                    completion(.failure(BitcoinError.failedToBuildTransaction))
                    return
                }
                let txHexString = "0x\(tx.toHexString())"
                //send tx
                
            case .completion(let error):
                if let error = error {
                    completion(.failure(error))
                }
            }
        }
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
                    completion(.failure(EthereumError.failedToGetFee))
                    return
            }
            
            let minAmount = Amount(type: .coin, currencySymbol: self.wallet.blockchain.currencySymbol, value: minDecimal, address: self.wallet.address, decimals: self.wallet.blockchain.decimalCount)
            let normalAmount = Amount(type: .coin, currencySymbol: self.wallet.blockchain.currencySymbol, value: normalDecimal, address: self.wallet.address, decimals: self.wallet.blockchain.decimalCount)
            let maxAmount = Amount(type: .coin, currencySymbol: self.wallet.blockchain.currencySymbol, value: maxDecimal, address: self.wallet.address, decimals: self.wallet.blockchain.decimalCount)
            
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

    
    public var txCount: Int = -1
    public var pendingTxCount: Int = -1
    
    init(walletPublicKey: Data, isTestnet: Bool) {
        self.walletPublicKey = walletPublicKey
        self.isTestnet = isTestnet
    }
    
    public func buildForSign(transaction: Transaction) -> (hash: Data, transaction: EthereumTransaction)? {
        let nonceValue = BigUInt(txCount)
        
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
