//
//  CardanoEngine.swift
//  TangemKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Smart Cash AG. All rights reserved.
//

import Foundation
import SwiftCBOR
import CryptoSwift
import Sodium

open class CardanoEngine: CardEngine {
    
    static let kPendingTransactionTimeoutSeconds: Int = 60

    public unowned var card: CardViewModel
    
    var unspentOutputs: [CardanoUnspentOutput]?
    var transaction: CardanoTransaction?
    private let operationQueue = OperationQueue()
    
    public var blockchainDisplayName: String {
        return "Cardano"
    }
    
    public var walletType: WalletType {
        return .cardano
    }
    
    public var walletUnits: String {
        return "ADA"
    }
    
    public var qrCodePreffix: String {
        return ""
    }
    
    public var walletAddress: String = ""
    public var exploreLink: String {
        return "https://cardanoexplorer.com/address/" + walletAddress
    }
    
    public required init(card: CardViewModel) {
        self.card = card
        if card.isWallet {
            setupAddress()
        }
    }
    
    open func setupAddress() {
        let hexPublicKeyExtended = card.walletPublicKeyBytesArray + Array(repeating: 0, count: 32) 
        
        let forSha3 = ([0, [0, CBOR.byteString(hexPublicKeyExtended)], [:]] as CBOR).encode()
        
        let sha = forSha3.sha3(.sha256)
        let pkHash = Sodium().genericHash.hash(message: sha, outputLength: 28)!
        
        let addr = ([CBOR.byteString(pkHash), [:], 0] as CBOR).encode()
        let checksum = UInt64(addr.crc32())
        
        let addrItem = CBOR.tagged(CBOR.Tag(rawValue: 24), CBOR.byteString(addr)) 
        
        let hexAddress = ([addrItem, CBOR.unsignedInt(checksum)] as CBOR).encode()
        
        walletAddress = String(base58Encoding: Data(bytes: hexAddress))
        
        card.node = "explorer2.adalite.io"
    }
    
    public var coinTraitCollection: CoinTrait {
        return [.allowsFeeInclude]
       }
    
    public func validate(address: String) -> Bool {
        guard !address.isEmpty else {
            return false;
        }
        
        guard let decoded58 = address.base58DecodedData?.bytes,
            decoded58.count > 0 else {
            return false
        }
        
        guard let cborArray = (try? CBORDecoder(input: decoded58).decodeItem()) as? CBOR,
            let addressArray = cborArray[0],
            let checkSumArray = cborArray[1] else {
                return false
        }
        
        guard case let CBOR.tagged(_, cborByteString) = addressArray,
            case let CBOR.byteString(addressBytes) = cborByteString else {
            return false
        }
        
        guard case let CBOR.unsignedInt(checksum) = checkSumArray else {
            return false
        }
    
        let calculatedChecksum = UInt64(addressBytes.crc32())
        return calculatedChecksum == checksum
    }
    
    public var hasPendingTransactions: Bool {
        return CardanoPendingTransactionsStorage.shared.hasPendingTransactions(card)
    }
    
    public func getHashForSignature(amount: String, fee: String, includeFee: Bool, targetAddress: String) -> [Data]? {
        guard let unspentOutputs = unspentOutputs else {
            assertionFailure()
            return nil
        }
        
        let tokenDecimal = card.tokenDecimal ?? Int(Blockchain.cardano.decimalCount)
        let fee = NSDecimalNumber(string: fee).multiplying(byPowerOf10: Int16(tokenDecimal), withBehavior: nil).stringValue
        let amount = NSDecimalNumber(string: amount).multiplying(byPowerOf10: Int16(tokenDecimal), withBehavior: nil).stringValue
        let walletValue = NSDecimalNumber(string: card.walletValue).multiplying(byPowerOf10: Int16(tokenDecimal), withBehavior: nil).stringValue
        let transaction = builTxForSign(unspentOutputs: unspentOutputs, targetAddress: targetAddress, amount: amount, walletBalance: walletValue, feeValue: fee, isIncludeFee: includeFee)
        
        guard let transactionHash = transaction.dataToSign else {
            assertionFailure()
            return nil
        }
        
        self.transaction = transaction
        
        return [Data(bytes: transactionHash)]
    }
    
    open func builTxForSign(unspentOutputs: [CardanoUnspentOutput], targetAddress: String, amount: String, walletBalance: String, feeValue: String, isIncludeFee: Bool) -> CardanoTransaction {
        return CardanoTransaction(unspentOutputs: unspentOutputs,
                                  cardWalletAddress: walletAddress,
                                  targetAddress: targetAddress,
                                  amount: amount,
                                  walletBalance: walletBalance,
                                  feeValue: feeValue,
                                  isIncludeFee: isIncludeFee)
    }
    
    func buildTxForSend(signFromCard: [UInt8]) -> [UInt8]? {
        let hexPublicKeyExtended = card.walletPublicKeyBytesArray + Array(repeating: 0, count: 32)
        let witnessBodyCBOR = [CBOR.byteString(hexPublicKeyExtended), CBOR.byteString(signFromCard)] as CBOR

        let witnessBodyItem = CBOR.tagged(.encodedCBORDataItem, CBOR.byteString(witnessBodyCBOR.encode()))

        guard let unspentOutputs = unspentOutputs, let transactionBody = transaction?.transactionBody else {
            assertionFailure()
            return nil
        }

        var unspentOutputsCBOR = [CBOR]()
        for _ in unspentOutputs {
            let array = [0, witnessBodyItem] as CBOR
            unspentOutputsCBOR.append(array)
        }

        let witness = CBOR.array(unspentOutputsCBOR).encode()

        var txForSend = [UInt8]()
        txForSend.append(0x82)
        txForSend.append(contentsOf: transactionBody)
        txForSend.append(contentsOf: witness)

        return txForSend
    }
    
    public func sendToBlockchain(signFromCard: [UInt8], completion: @escaping (Bool, Error?) -> Void) {
        guard let txForSend = buildTxForSend(signFromCard: signFromCard) else {
            assertionFailure()
            completion(false, "Empty transaction. Try again")
            return
        }
        
        let operation = getSendOperation(bytes: txForSend)
        operation.completion = { (result) in
            switch result {
            case .success(let success):
                guard success else {
                    completion(false, "Operation failed")
                    return
                }
        
                guard let transactionId = self.transaction?.transactionHash?.hexDescription() else {
                    assertionFailure()
                    completion(false, "Empty transaction id. Try again")
                    return
                }
                
                CardanoPendingTransactionsStorage.shared.append(transactionId: transactionId,
                                                                card: self.card,
                                                                expirationTimeoutSeconds: CardanoEngine.kPendingTransactionTimeoutSeconds)
                completion(true, nil)
            case .failure(let error):
               // print(error)
                completion(false, error)
            }
        }
        
        operationQueue.addOperation(operation)
    }
    
    open func getSendOperation(bytes: [UInt8]) -> BlockchainTxOperation {
        return CardanoSendTransactionOperation(bytes: bytes)
    }
    
    public func getFee(targetAddress: String, amount: String, completion: @escaping ((min: String, normal: String, max: String)?) -> Void) {
        guard let unspentOutputs = unspentOutputs else {
            assertionFailure()
            completion((min: "", normal: "", max: ""))
            return
        }
        
        let tokenDecimal = card.tokenDecimal ?? Int(Blockchain.cardano.decimalCount)
        let dummyFee = NSDecimalNumber(0.000001).multiplying(byPowerOf10: Int16(tokenDecimal), withBehavior: nil).stringValue
        let amount = NSDecimalNumber(string: amount).multiplying(byPowerOf10: Int16(tokenDecimal), withBehavior: nil).stringValue
        let walletValue = NSDecimalNumber(string: card.walletValue).multiplying(byPowerOf10: Int16(tokenDecimal), withBehavior: nil).stringValue
        let dummyTransaction = CardanoTransaction(unspentOutputs: unspentOutputs,
                                                  cardWalletAddress: walletAddress,
                                                  targetAddress: targetAddress,
                                                  amount: amount,
                                                  walletBalance: walletValue,
                                                  feeValue: dummyFee,
                                                  isIncludeFee: true)
        self.transaction = dummyTransaction
        let dummySign:[UInt8] = Array(repeating: 0, count: 64)

        let a = Decimal(0.155381)
        let b = Decimal(0.000043946)
        
        guard let transactionSize = buildTxForSend(signFromCard: dummySign)?.count else {
            assertionFailure()
            self.transaction = nil
            completion((min: "", normal: "", max: ""))
            return
        }
        let feeValue = a + b * Decimal(transactionSize)
        self.transaction = nil
        let feeRounded = feeValue.rounded(blockchain: .cardano)
        let fee = "\(feeRounded)"
        
        completion((min: fee, normal: fee, max: fee))
    }
    
}

extension CardanoEngine: CoinProvider {
    public func getApiDescription() -> String {
        return CardanoBackend.current == CardanoBackend.adaliteURL1 ? "1" : "2"
    }
}
