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


class EthereumTransactionBuilder {
    private let walletPublicKey: Data
    private let isTestnet: Bool
    private let chainId: BigUInt = 1
    
    init(walletPublicKey: Data, isTestnet: Bool) {
        self.walletPublicKey = walletPublicKey
        self.isTestnet = isTestnet
    }
    
//    public func buildForSign(transaction: Transaction) -> (hash: Data?, transaction: EthereumTransaction) {
//
//    }
    
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
    
    func getGasLimit(for amount: Amount) -> BigUInt {
        if amount.type == .coin {
            return 21000
        }
        
        if amount.currencySymbol == "DGX" {
            return 300000
        }
        
        return 60000
    }
}

//extension EthereumWalletManager: TransactionSender {
//    func send(_ transaction: Transaction, signer: TransactionSigner, completion: @escaping (Result<Bool, Error>) -> Void) {
//        txBuilder.buildForSign(transaction: transaction) {[weak self] buildForSignResponse in
//            guard let self = self else { return }
//
//            guard let buildForSignResponse = buildForSignResponse else {
//                completion(.failure(StellarError.failedToBuildTransaction))
//                return
//            }
//
//            signer.sign(hashes: [buildForSignResponse.hash], cardId: self.cardId) {[weak self] result in
//                switch result {
//                case .event(let response):
//                    guard let self = self else { return }
//
//                    guard let tx = self.txBuilder.buildForSend(signature: response.signature, transaction: buildForSignResponse.transaction) else {
//                        completion(.failure(BitcoinError.failedToBuildTransaction))
//                        return
//                    }
//
//                    self.stellarSdk.transactions.postTransaction(transactionEnvelope: tx) {[weak self] postResponse -> Void in
//                        switch postResponse {
//                        case .success(let submitTransactionResponse):
//                            if submitTransactionResponse.transactionResult.code == .success {
//                                //self?.latestTxDate = Date()
//                                completion(.success(true))
//                            } else {
//                                print(submitTransactionResponse.transactionResult.code)
//                                completion(.failure("Result code: \(submitTransactionResponse.transactionResult.code)"))
//                            }
//                        case .failure(let horizonRequestError):
//                            let horizonMessage = horizonRequestError.message
//                            let json = JSON(parseJSON: horizonMessage)
//                            let detailMessage = json["detail"].stringValue
//                            let extras = json["extras"]
//                            let codes = extras["result_codes"].rawString() ?? ""
//                            let errorMessage: String = (!detailMessage.isEmpty && !codes.isEmpty) ? "\(detailMessage). Codes: \(codes)" : horizonMessage
//                            completion(.failure(errorMessage))
//                        }
//                    }
//
//                case .completion(let error):
//                    if let error = error {
//                        completion(.failure(error))
//                    }
//                }
//            }
//        }
//    }
//
//}

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
