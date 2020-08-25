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

open class CardanoEngine: CardEngine, PayIdProvider, DetailedError {
    var errorText: String? = nil
    let isShelleyFork: Bool
    private static let ADDRESS_HEADER_BYTE = Data([UInt8(97)])
    
    static let kPendingTransactionTimeoutSeconds: Int = 60
    static let BECH32_HRP = "addr1"
    
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
    
    let payIdManager: PayIdManager? = PayIdManager(network: .ADA)
    
    public var walletAddress: String = ""
    public var exploreLink: String {
        return "https://cardanoexplorer.com/address/" + walletAddress
    }
    
    public required init(card: CardViewModel) {
        self.card = card
        self.isShelleyFork = card.blockchain == .cardanoShelley
        if card.isWallet {
            setupAddress()
        }
    }
    
    open func setupAddress() {
        if isShelleyFork {
            let publicKeyHash = Sodium().genericHash.hash(message: card.walletPublicKeyBytesArray, outputLength: 28)!
            let addressBytes = CardanoEngine.ADDRESS_HEADER_BYTE + publicKeyHash
            let bech32 = Bech32Internal()
            let convertedAddressBytes = try! bech32.convertBits(data: Array(addressBytes), fromBits: 8, toBits: 5, pad: true)
            walletAddress = bech32.encode("addr", values: Data(convertedAddressBytes))
        } else {
            let hexPublicKeyExtended = card.walletPublicKeyBytesArray + Array(repeating: 0, count: 32)
            
            let forSha3 = ([0, [0, CBOR.byteString(hexPublicKeyExtended)], [:]] as CBOR).encode()
            
            let sha = forSha3.sha3(.sha256)
            let pkHash = Sodium().genericHash.hash(message: sha, outputLength: 28)!
            
            let addr = ([CBOR.byteString(pkHash), [:], 0] as CBOR).encode()
            let checksum = UInt64(addr.crc32())
            
            let addrItem = CBOR.tagged(CBOR.Tag(rawValue: 24), CBOR.byteString(addr))
            
            let hexAddress = ([addrItem, CBOR.unsignedInt(checksum)] as CBOR).encode()
            
            walletAddress = String(base58Encoding: Data(bytes: hexAddress), alphabet:Base58String.btcAlphabet)
        }
        card.node = "explorer2.adalite.io"
    }
    
    
    
    public var coinTraitCollection: CoinTrait {
        return [.allowsFeeInclude]
       }
    
    public func validate(address: String) -> Bool {
        guard !address.isEmpty else {
            return false;
        }
        
        if address.starts(with: CardanoEngine.BECH32_HRP) {
            if let _ = try? Bech32Internal().decodeLong(address) {
                return true
            } else {
                return false
            }
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
        errorText = nil
        guard let unspentOutputs = unspentOutputs else {
            assertionFailure()
            return nil
        }
        
        let tokenDecimal = card.tokenDecimal ?? Int(Blockchain.cardano.decimalCount)
        let fee = NSDecimalNumber(string: fee).multiplying(byPowerOf10: Int16(tokenDecimal), withBehavior: nil).stringValue
        let amount = NSDecimalNumber(string: amount).multiplying(byPowerOf10: Int16(tokenDecimal), withBehavior: nil).stringValue
        let walletValue = NSDecimalNumber(string: card.walletValue).multiplying(byPowerOf10: Int16(tokenDecimal), withBehavior: nil).stringValue
        let transaction = builTxForSign(unspentOutputs: unspentOutputs, targetAddress: targetAddress, amount: amount, walletBalance: walletValue, feeValue: fee, isIncludeFee: includeFee)
        
        errorText = transaction.errorText
        
        guard let transactionHash = transaction.dataToSign else {
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
                                  isIncludeFee: isIncludeFee,
                                  isShelleyFork: isShelleyFork)
    }
    
    func buildTxForSend(signFromCard: [UInt8]) -> [UInt8]? {
        guard let transactionBodyItem = transaction?.transactionBodyItem else {
            assertionFailure()
            return nil
        }
        
        let witnessDataItem = isShelleyFork ?
            CBOR.array([CBOR.array([CBOR.byteString(card.walletPublicKeyBytesArray),
                                                          CBOR.byteString(signFromCard)])])
        : CBOR.array([CBOR.array([CBOR.byteString(card.walletPublicKeyBytesArray),
                                                      CBOR.byteString(signFromCard),
                                                      CBOR.byteString(Data(hex: "0000000000000000000000000000000000000000000000000000000000000000").bytes),
                                                      CBOR.byteString(Data(hex: "A0").bytes)
        ])])
        
        let witnessMap = CBOR.map([CBOR.unsignedInt(isShelleyFork ? 0 : 2) : witnessDataItem])
        let tx = CBOR.array([transactionBodyItem, witnessMap, nil])
        let txForSend = tx.encode()
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
        let amount = NSDecimalNumber(string: amount).multiplying(byPowerOf10: Int16(tokenDecimal), withBehavior: nil)
        let walletValue = NSDecimalNumber(string: card.walletValue).multiplying(byPowerOf10: Int16(tokenDecimal), withBehavior: nil)
        let outputsNumber = amount == walletValue ? 1 : 2
        let transactionSize = unspentOutputs.count * 40 + outputsNumber * 65 + 160
    
        let a = Decimal(0.155381)
        let b = Decimal(0.000043946)
        
        let feeValue = a + b * Decimal(transactionSize)
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
