//
//  CardParser.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 dns user. All rights reserved.
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
            DispatchQueue.main.async {
                self.completion(CardParsingResult.tlvError)
            }
            return
        }
        
        let payloadSize = payloadArr.count
        var offset: Int = 0
        
        guard let _ = TLV.checkPIN(payloadArr, &offset) else {
            DispatchQueue.main.async {
                self.completion(CardParsingResult.locked)
            }
            return
        }
        
        var card = Card()
        
        var cardArr = [UInt8]()
        while (offset < payloadSize) {
            var tlv: TLV!
            do {
                tlv = try TLV(data: payloadArr, &offset)
            } catch {
                DispatchQueue.main.async {
                    self.completion(CardParsingResult.tlvError)
                }
            }
            
            if tlv.tagName == "Card_Data" {
                cardArr = tlv.hexBinaryValues
            }
            if tlv.tagName == "CardID" {
                card.cardID = tlv.stringValue
            }
            if tlv.tagName == "RemainingSignatures" {
                card.remainingSignatures = tlv.stringValue
            }
            if tlv.tagName == "Wallet_PublicKey" {
                card.isWallet = true
                card.hexPublicKey = tlv.hexStringValue
                card.pubArr = tlv.hexBinaryValues
            }
            if tlv.tagName == "Wallet_Signature"{
                card.signArr = tlv.hexBinaryValues
            }
            if tlv.tagName == "Salt" {
                card.salt = tlv.hexStringValue.lowercased()
            }
            if tlv.tagName == "Challenge" {
                card.challenge = tlv.hexStringValue.lowercased()
            }
            if tlv.tagName == "SignedHashes" {
                card.signedHashes = tlv.hexStringValue
            }
            if tlv.tagName == "Firmware" {
                card.firmware = tlv.stringValue
            }
        }
        
        guard card.isWallet else {
            card.ribbonCase = checkRibbonCase(card)
            DispatchQueue.main.async {
                self.completion(CardParsingResult.success(card))
            }
            return
        }
        
        let cardArrSize = cardArr.count
        var cardOffset: Int = 0
        while (cardOffset < cardArrSize){
            var tlv: TLV!
            do {
                tlv = try TLV(data: cardArr, &cardOffset)
            } catch {
                DispatchQueue.main.async {
                    self.completion(CardParsingResult.tlvError)
                }
            }
            
            guard tlv != nil else {
                continue
            }
            
            if tlv.tagName == "Blockchain_Name" {
                card.blockchainName = tlv.stringValue
            }
            if tlv.tagName == "Issuer_Name" {
                card.issuer = tlv.stringValue
            }
            if tlv.tagName == "Manufacture_Date_Time" {
                card.manufactureDateTime = tlv.stringValue
            }
            if tlv.tagName == "Batch_ID" {
                card.batchId = Int(tlv.hexStringValue, radix: 16)!
            }
            if tlv.tagName == "SignedHashes" {
                card.signedHashes = tlv.hexStringValue
            }
            if tlv.tagName == "Token_Symbol" {
                card.tokenSymbol = tlv.stringValue
            }
            if tlv.tagName == "Token_Contract_Address" {
                card.tokenContractAddress = tlv.stringValue
            }
            if tlv.tagName == "Token_Decimal" {
                card.tokenDecimal = Int(tlv.hexStringValue, radix: 16)!
            }
            if tlv.tagName == "Manufacturer_Signature" {
                card.manufactureSignature = tlv.hexStringValue
            }
            
        }
        
        card.ribbonCase = checkRibbonCase(card)
        
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
            card.checkedBalance = false
            
            DispatchQueue.main.async {
                self.completion(CardParsingResult.success(card))
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
            
            card.checkedBalance = false
            DispatchQueue.main.async {
                self.completion(CardParsingResult.success(card))
            }
        }
        
    }
    
}
