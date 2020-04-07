//
//  CardanoTransaction.swift
//  TangemKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Smart Cash AG. All rights reserved.
//

import Foundation
import SwiftCBOR
import Sodium

open class CardanoTransaction {
    
    let unspentOutputs: [CardanoUnspentOutput]
    let cardWalletAddress: String
    let targetAddress: String
    let amount: String
    let feeValue: String
    let walletBalance: String
    
    let isIncludeFee: Bool
    
    let kDecimalNumber: Int16 = 6
    
    let kProtocolMagic: UInt64 = 764824073
    
    public var transactionBody: [UInt8]?
    public var transactionHash: [UInt8]?
    public var dataToSign: [UInt8]?
    
    public init(unspentOutputs: [CardanoUnspentOutput], cardWalletAddress: String, targetAddress: String, amount: String, walletBalance: String, feeValue: String, isIncludeFee: Bool) {
        self.cardWalletAddress = cardWalletAddress
        self.targetAddress = targetAddress
        self.unspentOutputs = unspentOutputs
        self.amount = amount
        self.walletBalance = walletBalance
        self.feeValue = feeValue
        self.isIncludeFee = isIncludeFee
        
        buildTransaction()
    }
    
    open func buildTransaction() {
        
        guard var amount = Decimal(string: self.amount), let fullAmount = Decimal(string: self.walletBalance), let fees = Decimal(string: feeValue) else {
            assertionFailure()
            return
        }  
        
        var change = fullAmount - amount
        if isIncludeFee {
            amount -= fees
        } else {
            change -= fees
        }
        
        let amountLong = (amount as NSDecimalNumber).uint64Value
        let changeLong = (change as NSDecimalNumber).uint64Value
        
        var unspentOutputsCBOR = [CBOR]()
        for output in unspentOutputs {
            let outputCBOR = [CBOR.byteString(Array(output.id.hexData()!)), CBOR.unsignedInt(UInt64(output.index))] as CBOR
            let array = [0, CBOR.tagged(.encodedCBORDataItem, CBOR.byteString(outputCBOR.encode()))] as CBOR
            unspentOutputsCBOR.append(array)
        }
        
        let targetAddressBytes: [UInt8] = Array(targetAddress.base58DecodedData!)
        guard let targetAddressItem = try? CBORDecoder(input: targetAddressBytes).decodeItem(), let targetAddressItemCBOR = targetAddressItem else {
            assertionFailure()
            return
        }
        
        var transactionOutputsCBOR = [CBOR]()
        transactionOutputsCBOR.append(CBOR.array([targetAddressItemCBOR, CBOR.unsignedInt(amountLong)]))
        
        let currentWalletAddressBytes: [UInt8] = Array(cardWalletAddress.base58DecodedData!)
        guard let currentWalletAddressItem = try? CBORDecoder(input: currentWalletAddressBytes).decodeItem(), let currentWalletAddressCBOR = currentWalletAddressItem else {
            assertionFailure()
            return
        }
        if (changeLong > 0) {
            transactionOutputsCBOR.append(CBOR.array([currentWalletAddressCBOR, CBOR.unsignedInt(changeLong)]))
        }
        let transactionInputsArray = CBOR.indefiniteLenghtArrayWith(unspentOutputsCBOR)
        let transactionOutputsArray = CBOR.indefiniteLenghtArrayWith(transactionOutputsCBOR)
        
        let transactionBody = CBOR.combineEncodedArrays([transactionInputsArray, transactionOutputsArray, CBOR.map([:]).encode()])
        
        guard let transactionHash = Sodium().genericHash.hash(message: transactionBody, outputLength: 32) else {
            assertionFailure()
            return
        }
        
        let magic = CBOR.unsignedInt(kProtocolMagic).encode()
        
        var dataToSign = [UInt8]()
        dataToSign.append(0x01)
        dataToSign.append(contentsOf: magic)
        dataToSign.append(contentsOf: [0x58, 0x20])
        dataToSign.append(contentsOf: transactionHash)
        
        self.transactionBody = transactionBody
        self.transactionHash = transactionHash
        self.dataToSign = dataToSign
    }
    
}

extension CBOR {
    
    public static func indefiniteLenghtArrayWith(_ elements: [CBOR]) -> [UInt8] {
        var result = CBOR.encodeArrayStreamStart()
        result += CBOR.encodeArrayChunk(elements) 
        result += CBOR.encodeStreamEnd()
        return result
    }
    
    public static func combineEncodedArrays(_ encodedArrays: [[UInt8]]) -> [UInt8] {
        var res = encodedArrays.count.encode()
        res[0] = res[0] | 0b100_00000
        res.append(contentsOf: encodedArrays.reduce(into: [], { (result, array) in
            result += array
        }))
        return res
    }
    
    public static func encodeUnspentOutput(_ output: String, index: UInt8) -> [UInt8] {
        var res = 2.encode()
        res[0] = res[0] | 0b100_00000
        
        let outputBytes = output.toUInt8
        var resString = outputBytes.count.encode()
        resString[0] = resString[0] | 0b010_00000
        res.append(contentsOf: resString)
        
        res.append(contentsOf: output.toUInt8)
        res.append(index)
        
        return res
        
    }
    
}
