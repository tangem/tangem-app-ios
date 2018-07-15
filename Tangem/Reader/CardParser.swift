//
//  CardParser.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 dns user. All rights reserved.
//

import UIKit

class CardParser: Any {
    
    func parse(payload: String, onCardLocked: () -> Void, onWrongTLV: () -> Void, onSuccess: (Card) -> Void){
        //Check if Hex String is corect
        guard let payloadArr = payload.asciiHexToData()else {
            print("Error of payload")
            return
        }
        let payloadSize = payloadArr.count
        var offset: Int = 0
        
        //Check if Card is locked
        guard let _ = TLV.checkPIN(payloadArr,&offset) else {
            onCardLocked()
            return
        }
        
        var tmpCard = Card()
        
        var cardArr = [UInt8]()
        var cardArrSize = 0
        var cardOffset:Int = 0
        while (offset < payloadSize){
            var tlv: TLV!
            do {
                tlv = try TLV(data: payloadArr, &offset)
            } catch TLVError.wrongTLV {
                onWrongTLV()
            } catch {
                
            }
            
            print("TLV after Name: \(tlv.name)")
            print("TLV after Tag: \(tlv.tagTLV)")
            print("TLV after LengthTLV: \(tlv.lengthTLV)")
            print("TLV after TagTLVHex: \(tlv.tagTLVHex)")
            print("TLV after ValueTLV: \(tlv.valueTLV)")
            print("Ready For Display: \(tlv.readyValue)")
            print("Ready Hex: \(tlv.valueHex)")
            
            if tlv.name == "Card_Data" {
                cardArr = tlv.valueTLV
            }
            if tlv.name == "CardID" {
                tmpCard.cardID = tlv.readyValue
            }
            if tlv.name == "RemainingSignatures" {
                tmpCard.remainingSignatures = tlv.readyValue
            }
            if tlv.name == "Wallet_PublicKey" {
                tmpCard.isWallet = true
                tmpCard.hexPublicKey = tlv.valueHex
                tmpCard.pubArr = tlv.valueTLV
            }
            if tlv.name == "Wallet_Signature"{
                tmpCard.signArr = tlv.valueTLV
            }
            if tlv.name == "Salt" {
                tmpCard.salt = tlv.valueHex.lowercased()
            }
            if tlv.name == "Challenge" {
                tmpCard.challenge = tlv.valueHex.lowercased()
            }
            if tlv.name == "SignedHashes" {
                tmpCard.signedHashes = tlv.valueHex
            }
            
        }
        if tmpCard.isWallet {
            cardArrSize = cardArr.count
            while (cardOffset < cardArrSize){
                var tmp: TLV!
                do {
                    tmp = try TLV(data: cardArr,&cardOffset)
                } catch TLVError.wrongTLV {
                    onWrongTLV()
                } catch {
                    
                }
                
                print("TLV after Name: \(tmp.name)")
                print("TLV after Tag: \(tmp.tagTLV)")
                print("TLV after LengthTLV: \(tmp.lengthTLV)")
                print("TLV after TagTLVHex: \(tmp.tagTLVHex)")
                print("TLV after ValueTLV: \(tmp.valueTLV)")
                print("Ready For Display: \(tmp.readyValue)")
                
                if tmp.name == "Blockchain_Name" {
                    tmpCard.blockchainName = tmp.readyValue
                }
                if tmp.name == "Issuer_Name" {
                    tmpCard.issuer = tmp.readyValue
                }
                if tmp.name == "Firmware" {
                    tmpCard.firmware = tmp.readyValue
                }
                if tmp.name == "Manufacture_Date_Time" {
                    tmpCard.manufactureDateTime = tmp.readyValue
                }
                if tmp.name == "SignedHashes" {
                    tmpCard.signedHashes = tmp.valueHex
                }
                
            }
            //Ribbon Check
            tmpCard.ribbonCase = checkRibbonCase(tmpCard)
            
            let Blockchain = tmpCard.blockchainName
            
            if Blockchain.containsIgnoringCase(find: "bitcoin") || Blockchain.containsIgnoringCase(find: "btc") {
                //We think that card is BTC
                tmpCard.type = .btc
                tmpCard.blockchain = "Bitcoin"
                tmpCard.node = randomNode()
                if Blockchain.containsIgnoringCase(find: "test"){
                    tmpCard.isTestNet = true
                    tmpCard.blockchain = "Bitcoin TestNet"
                    tmpCard.node = randomTestNode()
                }
                if let addr = getAddress(tmpCard.hexPublicKey) {
                    tmpCard.btcAddressMain = addr[0]
                    tmpCard.btcAddressTest = addr[1]
                }
                tmpCard.walletUnits = "mBTC"
                if !tmpCard.isTestNet {
                    tmpCard.address = tmpCard.btcAddressMain
                    tmpCard.link = Links.bitcoinMainLink + tmpCard.address
                } else {
                    tmpCard.address = tmpCard.btcAddressTest
                    tmpCard.link = Links.bitcoinTestLink + tmpCard.address
                }
                tmpCard.checkedBalance = false
                
                onSuccess(tmpCard)
            }
            if Blockchain.containsIgnoringCase(find: "eth") {
                //We think that card is ETC
                tmpCard.type = .eth
                tmpCard.blockchain = "Ethereum"
                tmpCard.node = "mainnet.infura.io"
                if Blockchain.containsIgnoringCase(find: "test"){
                    tmpCard.isTestNet = true
                    tmpCard.blockchain = "Ethereum Rinkeby"
                    tmpCard.node = "rinkeby.infura.io"
                }
                tmpCard.ethAddress = getEthAddress(tmpCard.hexPublicKey)
                tmpCard.walletUnits = "ETH"
                tmpCard.address = tmpCard.ethAddress
                if !tmpCard.isTestNet {
                    tmpCard.link = Links.ethereumMainLink + tmpCard.address
                } else {
                    tmpCard.link = Links.ethereumTestLink + tmpCard.address
                }
                
                tmpCard.checkedBalance = false
                onSuccess(tmpCard)

            }
            
            
        } else {
            //Ribbon Check
            tmpCard.ribbonCase = checkRibbonCase(tmpCard)
            
            onSuccess(tmpCard)
        }
    }
    
}
