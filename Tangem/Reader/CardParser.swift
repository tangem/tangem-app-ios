//
//  CardParser.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 dns user. All rights reserved.
//

import UIKit

protocol CardParserDelegate: class {
    func cardParserLockedCard(_ parser: CardParser)
    func cardParserWrongTLV(_ parser: CardParser)
    func cardParser(_ parser: CardParser, didFinishWith card: Card)
}

class CardParser: Any {
    
    weak var delegate: CardParserDelegate?
    
    init(delegate: CardParserDelegate) {
        self.delegate = delegate
    }
    
    func parse(payload: String) {
        
        guard let payloadArr = payload.asciiHexToData()else {
            print("Error of payload")
            return
        }
        
        let payloadSize = payloadArr.count
        var offset: Int = 0
        
        //Check if Card is locked
        guard let _ = TLV.checkPIN(payloadArr,&offset) else {
            self.delegate?.cardParserLockedCard(self)
            return
        }
        
        var card = Card()
        
        var cardArr = [UInt8]()
        while (offset < payloadSize){
            var tlv: TLV!
            do {
                tlv = try TLV(data: payloadArr, &offset)
            } catch TLVError.wrongTLV {
                self.delegate?.cardParserWrongTLV(self)
            } catch {
                
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
        }
        
        guard card.isWallet else {
            //Ribbon Check
            card.ribbonCase = checkRibbonCase(card)
            
            self.delegate?.cardParser(self, didFinishWith: card)
            return
        }
        
        let cardArrSize = cardArr.count
        var cardOffset: Int = 0
        while (cardOffset < cardArrSize){
            var tlv: TLV!
            do {
                tlv = try TLV(data: cardArr, &cardOffset)
            } catch TLVError.wrongTLV {
                self.delegate?.cardParserWrongTLV(self)
            } catch {
                
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
            if tlv.tagName == "Firmware" {
                card.firmware = tlv.stringValue
            }
            if tlv.tagName == "Manufacture_Date_Time" {
                card.manufactureDateTime = tlv.stringValue
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
                card.tokenDecimal =  Int(tlv.hexStringValue, radix: 16)!
            }
            
        }
        //Ribbon Check
        card.ribbonCase = checkRibbonCase(card)
        
        let blockchainName = card.blockchainName
        
        if blockchainName.containsIgnoringCase(find: "bitcoin") || blockchainName.containsIgnoringCase(find: "btc") {
            //We think that card is BTC
            card.type = .btc
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
            
            self.delegate?.cardParser(self, didFinishWith: card)
        }
        
        if blockchainName.containsIgnoringCase(find: "eth") {
            //We think that card is ETC
            if card.tokenSymbol == "SEED" {
                card.type = .seed
            } else {
                card.type = .eth
            }

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
            self.delegate?.cardParser(self, didFinishWith: card)

        }
    }
    
}
