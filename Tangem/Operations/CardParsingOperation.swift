//
//  CardParser.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Smart Cash AG. All rights reserved.
//

import UIKit
import CoreNFC

class CardParsingOperation: Operation {
    
    enum CardParsingResult {
        case success(Card)
        case tlvError
        case locked
    }
    
    var payload: Data
    var completion: (CardParsingResult) -> Void
    
    init(payload: Data, completion: @escaping (CardParsingResult) -> Void) {
        self.payload = payload
        self.completion = completion
    }
    
    override func main() {
        
        let hexPayload = payload.reduce("") {
            return $0 + $1.toAsciiHex()
        }
        
        guard let payloadArr = hexPayload.asciiHexToData() else {
            completeOperationWith(result: CardParsingResult.tlvError)
            return
        }
        
        var offset: Int = 0
        
        guard !TLV.isLockedPIN(payloadArr, &offset) else {
            completeOperationWith(result: CardParsingResult.locked)
            return
        }
        
        var card = Card()
        var cardDataArray = [UInt8]()
        
        processCardGeneralInfo(&offset, payloadArr, &cardDataArray, &card)
        card.ribbonCase = checkRibbonCase(card)
        
        guard card.isWallet else {
            completeOperationWith(result: CardParsingResult.success(card))
            return
        }
        
        processCardDataArray(cardDataArray, &card)
        assignCardType(&card)
        
        completeOperationWith(result: CardParsingResult.success(card))
    }
    
    func completeOperationWith(result: CardParsingResult) {
        DispatchQueue.main.async {
            self.completion(result)
        }
    }
    
    func processCardGeneralInfo(_ offset: inout Int, _ payloadArr: [UInt8], _ cardDataArray: inout [UInt8], _ card: inout Card) {
        let payloadSize = payloadArr.count
        while (offset < payloadSize) {
            var tlv: TLV!
            do {
                tlv = try TLV(data: payloadArr, &offset)
            } catch {
                completeOperationWith(result: CardParsingResult.tlvError)
            }
            
            if tlv.tagName == .cardData {
                cardDataArray = tlv.hexBinaryValues
            }
            if tlv.tagName == .cardId {
                card.cardID = tlv.stringValue
            }
            if tlv.tagName == .remainingSignatures {
                card.remainingSignatures = tlv.stringValue
            }
            if tlv.tagName == .walletPublicKey {
                card.isWallet = true
                card.hexPublicKey = tlv.hexStringValue
                card.pubArr = tlv.hexBinaryValues
            }
            if tlv.tagName == .walletSignature{
                card.signArr = tlv.hexBinaryValues
            }
            if tlv.tagName == .salt {
                card.salt = tlv.hexStringValue.lowercased()
            }
            if tlv.tagName == .challenge {
                card.challenge = tlv.hexStringValue.lowercased()
            }
            if tlv.tagName == .signedHashes {
                card.signedHashes = tlv.hexStringValue
            }
            if tlv.tagName == .firmware {
                card.firmware = tlv.stringValue
            }
        }
    }
    
    func processCardDataArray(_ cardDataArray: [UInt8], _ card: inout Card) {
        let cardArrSize = cardDataArray.count
        var cardOffset: Int = 0
        while (cardOffset < cardArrSize){
            var tlv: TLV!
            do {
                tlv = try TLV(data: cardDataArray, &cardOffset)
            } catch {
                completeOperationWith(result: CardParsingResult.tlvError)
            }
            
            guard tlv != nil else {
                continue
            }
            
            if tlv.tagName == .blockchainName {
                card.blockchainName = tlv.stringValue
            }
            if tlv.tagName == .issuerName {
                card.issuer = tlv.stringValue
            }
            if tlv.tagName == .manufacturerDateTime {
                card.manufactureDateTime = tlv.stringValue
            }
            if tlv.tagName == .batchId {
                card.batchId = Int(tlv.hexStringValue, radix: 16)!
            }
            if tlv.tagName == .signedHashes {
                card.signedHashes = tlv.hexStringValue
            }
            if tlv.tagName == .tokenSymbol {
                card.tokenSymbol = tlv.stringValue
            }
            if tlv.tagName == .tokenContractAddress {
                card.tokenContractAddress = tlv.stringValue
            }
            if tlv.tagName == .tokenDecimal {
                card.tokenDecimal = Int(tlv.hexStringValue, radix: 16)!
            }
            if tlv.tagName == .manufacturerSignature {
                card.manufactureSignature = tlv.hexStringValue
            }   
        }
    }
    
    func assignCardType(_ card: inout Card) {
        let blockchainName = card.blockchainName
        
        if card.type == .btc {
            card.blockchain = "Bitcoin"
            card.node = randomNode()
            if blockchainName.containsIgnoringCase(find: "test"){
                card.isTestNet = true
                card.blockchain = "Bitcoin TestNet"
                card.node = randomTestNode()
            }
            if let addr = getAddress(card.hexPublicKey) {
                card.btcAddressMain = addr[0]
                card.btcAddressTest = addr[1]
            }
            card.walletUnits = "BTC"
            if !card.isTestNet {
                card.address = card.btcAddressMain
                card.link = Links.bitcoinMainLink + card.address
            } else {
                card.address = card.btcAddressTest
                card.link = Links.bitcoinTestLink + card.address
            }
            
        } else {
            card.blockchain = "Ethereum"
            card.node = "mainnet.infura.io"
            if blockchainName.containsIgnoringCase(find: "test"){
                card.isTestNet = true
                card.blockchain = "Ethereum Rinkeby"
                card.node = "rinkeby.infura.io"
            }
            card.ethAddress = getEthAddress(card.hexPublicKey)
            card.walletUnits = card.tokenSymbol.isEmpty ? "ETH" : card.tokenSymbol
            card.address = card.ethAddress
            if !card.isTestNet {
                card.link = Links.ethereumMainLink + card.address
            } else {
                card.link = Links.ethereumTestLink + card.address
            }
        }
    }
    
}
