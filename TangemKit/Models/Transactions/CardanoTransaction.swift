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
    let isShelleyFork: Bool
    
    let unspentOutputs: [CardanoUnspentOutput]
    let cardWalletAddress: String
    let targetAddress: String
    let amount: String
    let feeValue: String
    let walletBalance: String
    
    let isIncludeFee: Bool
    
    let kDecimalNumber: Int16 = 6
    
    let kProtocolMagic: UInt64 = 764824073
    
    public var transactionBodyItem: CBOR?
    public var transactionHash: [UInt8]?
    public var dataToSign: [UInt8]?
    
    public var errorText: String? = nil
    
    public init(unspentOutputs: [CardanoUnspentOutput], cardWalletAddress: String, targetAddress: String, amount: String, walletBalance: String, feeValue: String, isIncludeFee: Bool, isShelleyFork: Bool) {
        self.cardWalletAddress = cardWalletAddress
        self.targetAddress = targetAddress
        self.unspentOutputs = unspentOutputs
        self.amount = amount
        self.walletBalance = walletBalance
        self.feeValue = feeValue
        self.isIncludeFee = isIncludeFee
        self.isShelleyFork = isShelleyFork
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
        let feesLong = (fees as NSDecimalNumber).uint64Value
        
        if (amountLong < 1000000 || (changeLong < 1000000 && changeLong != 0)) {
            errorText = "Sent amount and change cannot be less than 1 ADA"
            return
        }
        
        var targetAddressBytes = [UInt8]()
        if targetAddress.starts(with: CardanoEngine.BECH32_HRP) {
            let bech32 = Bech32Internal()
            if let decoded = try? bech32.decodeLong(targetAddress),
                let converted = try? bech32.convertBits(data: Array(decoded.checksum), fromBits: 5, toBits: 8, pad: false) {
                targetAddressBytes = converted
            } else {
                assertionFailure()
                return
            }
        } else {
            targetAddressBytes = Array(targetAddress.base58DecodedData!)
        }
        
        var transactionMap = CBOR.map([:])
        var inputsArray = [CBOR]()
        for unspentOutput in unspentOutputs {
            let array = CBOR.array(
                [CBOR.byteString(Array(unspentOutput.id.hexData()!)),
                 CBOR.unsignedInt(UInt64(unspentOutput.index))])
            inputsArray.append(array)
        }
        
        var outputsArray = [CBOR]()
        outputsArray.append(CBOR.array([CBOR.byteString(targetAddressBytes), CBOR.unsignedInt(amountLong)]))
            
        var changeAddressBytes: [UInt8]
        if isShelleyFork {
            let bech32 = Bech32Internal()
            let changeAddressDecoded = try! bech32.decode(cardWalletAddress).checksum
            changeAddressBytes = try! bech32.convertBits(data: Array(changeAddressDecoded), fromBits: 5, toBits: 8, pad: false)
        } else {
            changeAddressBytes = Array(cardWalletAddress.base58DecodedData!)
        }

        if (changeLong > 0) {
            outputsArray.append(CBOR.array([CBOR.byteString(changeAddressBytes), CBOR.unsignedInt(changeLong)]))
        }
        
        transactionMap[CBOR.unsignedInt(0)] = CBOR.array(inputsArray)
        transactionMap[CBOR.unsignedInt(1)] = CBOR.array(outputsArray)
        transactionMap[2] = CBOR.unsignedInt(feesLong)
        transactionMap[3] = CBOR.unsignedInt(90000000)
        
        let transactionBody = transactionMap.encode()
        guard let transactionHash = Sodium().genericHash.hash(message: transactionBody, outputLength: 32) else {
            assertionFailure()
            return
        }

        self.transactionBodyItem = transactionMap
        self.transactionHash = transactionHash
        self.dataToSign = transactionHash
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
