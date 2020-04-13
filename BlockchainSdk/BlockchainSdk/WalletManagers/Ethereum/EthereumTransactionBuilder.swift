//
//  EthereumTransactionBuilder.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import BigInt
import web3swift
import TangemSdk

class EthereumTransactionBuilder {
    private let walletPublicKey: Data
    private let isTestnet: Bool
    private let network: EthereumNetwork
    init(walletPublicKey: Data, isTestnet: Bool, network: EthereumNetwork ) {
        self.walletPublicKey = walletPublicKey
        self.isTestnet = isTestnet
        self.network = network
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
        
        guard let hashForSign = transaction.hashForSignature(chainID: network.chainId) else {
            return nil
        }
        
        return (hashForSign, transaction)
    }
    
    public func buildForSend(transaction: EthereumTransaction, hash: Data, signature: Data) -> Data? {
        var transaction = transaction
        guard let unmarshalledSignature = Secp256k1Utils.unmarshal(secp256k1Signature: signature, hash: hash, publicKey: walletPublicKey) else {
            return nil
        }
        
        transaction.v = BigUInt(unmarshalledSignature.v)
        transaction.r = BigUInt(unmarshalledSignature.r)
        transaction.s = BigUInt(unmarshalledSignature.s)
        
        let encodedBytesToSend = transaction.encodeForSend(chainID: network.chainId)
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
