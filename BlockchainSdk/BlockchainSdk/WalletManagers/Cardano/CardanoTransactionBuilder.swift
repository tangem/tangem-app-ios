//
//  CardanoTransactionBuilder.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftCBOR
import Sodium
import TangemSdk

class CardanoTransactionBuilder {
    let walletPublicKey: Data
    var unspentOutputs: [AdaliteUnspentOutput]? = nil
    let kDecimalNumber: Int16 = 6
    let kProtocolMagic: UInt64 = 764824073
    
    internal init(walletPublicKey: Data) {
        self.walletPublicKey = walletPublicKey
    }
    
    public func buildForSign(transaction: Transaction, walletAmount: Decimal) -> Data? {
        guard let transactionBody = buildTransactionBody(from: transaction, walletAmount: walletAmount) else {
             assertionFailure()
            return nil
        }

        guard let transactionHash = Sodium().genericHash.hash(message: transactionBody.toBytes, outputLength: 32) else {
            assertionFailure()
            return nil
        }
        
        let magic = CBOR.unsignedInt(kProtocolMagic).encode()
        var dataToSign = Data()
        dataToSign.append(UInt8(0x01))
        dataToSign.append(contentsOf: magic)
        dataToSign.append(contentsOf: [0x58, 0x20])
        dataToSign.append(contentsOf: transactionHash)
        return dataToSign
    }
    
    public func buildForSend(transaction: Transaction, walletAmount: Decimal, signature: Data) -> (tx: Data, hash: String)? {
        let hexPublicKeyExtended = walletPublicKey + Data(repeating: 0, count: 32)
        let witnessBodyCBOR = [CBOR.byteString(hexPublicKeyExtended.toBytes), CBOR.byteString(signature.toBytes)] as CBOR
        let witnessBodyItem = CBOR.tagged(.encodedCBORDataItem, CBOR.byteString(witnessBodyCBOR.encode()))
        
        guard let unspentOutputs = unspentOutputs, let transactionBody = buildTransactionBody(from: transaction, walletAmount: walletAmount) else {
            assertionFailure()
            return nil
        }
        
        var unspentOutputsCBOR = [CBOR]()
        for _ in unspentOutputs {
            let array = [0, witnessBodyItem] as CBOR
            unspentOutputsCBOR.append(array)
        }
        
        let witness = CBOR.array(unspentOutputsCBOR).encode()
        
        var txForSend = Data()
        txForSend.append(0x82)
        txForSend.append(contentsOf: transactionBody)
        txForSend.append(contentsOf: witness)
        
        guard let transactionHash = Sodium().genericHash.hash(message: transactionBody.toBytes, outputLength: 32) else {
            assertionFailure()
            return nil
        }
        
        return (tx: txForSend, hash: transactionHash.toHexString())
    }
    
    private func buildTransactionBody(from transaction: Transaction, walletAmount: Decimal) -> Data? {
        guard let fee = transaction.fee?.value,
            let amount = transaction.amount.value, let unspentOutputs = self.unspentOutputs else {
                return nil
        }
        let convertValue = pow(10, Blockchain.cardano.decimalCount)
        let feeConverted = fee * convertValue
        let amountConverted = amount * convertValue
        let walletAmountConverted = walletAmount * convertValue
        let change = walletAmountConverted - amountConverted - feeConverted
        
        let amountLong = (amountConverted as NSDecimalNumber).uint64Value
        let changeLong = (change as NSDecimalNumber).uint64Value
        
        var unspentOutputsCBOR = [CBOR]()
        for output in unspentOutputs {
            let outputCBOR = [CBOR.byteString(Array(Data(hexString: output.id))), CBOR.unsignedInt(UInt64(output.index))] as CBOR
            let array = [0, CBOR.tagged(.encodedCBORDataItem, CBOR.byteString(outputCBOR.encode()))] as CBOR
            unspentOutputsCBOR.append(array)
        }
        
        let targetAddressBytes: [UInt8] = Array(transaction.destinationAddress.base58DecodedData!)
        guard let targetAddressItemCBOR = try? CBORDecoder(input: targetAddressBytes).decodeItem() else {
            assertionFailure()
            return nil
        }
        
        var transactionOutputsCBOR = [CBOR]()
        transactionOutputsCBOR.append(CBOR.array([targetAddressItemCBOR, CBOR.unsignedInt(amountLong)]))
        
        let currentWalletAddressBytes: [UInt8] = Array(transaction.sourceAddress.base58DecodedData!)
        guard let currentWalletAddressCBOR = try? CBORDecoder(input: currentWalletAddressBytes).decodeItem() else {
            assertionFailure()
            return nil
        }
        if (changeLong > 0) {
            transactionOutputsCBOR.append(CBOR.array([currentWalletAddressCBOR, CBOR.unsignedInt(changeLong)]))
        }
        let transactionInputsArray = CBOR.indefiniteLenghtArrayWith(unspentOutputsCBOR)
        let transactionOutputsArray = CBOR.indefiniteLenghtArrayWith(transactionOutputsCBOR)
        
        let transactionBody = CBOR.combineEncodedArrays([transactionInputsArray, transactionOutputsArray, CBOR.map([:]).encode()])
        return Data(transactionBody)
    }
}

