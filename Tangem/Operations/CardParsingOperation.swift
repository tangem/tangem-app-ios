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
        
        var tlvArray = [TLV]()
        
        let payloadSize = payloadArr.count
        var cardDataArray = [UInt8]()
        while (offset < payloadSize) {
            var tlv: TLV!
            do {
                tlv = try TLV(data: payloadArr, &offset)
            } catch {
                completeOperationWith(result: CardParsingResult.tlvError)
            }
            
            if tlv.tagName == .cardData {
                cardDataArray = tlv.hexBinaryValues
            } else {
                tlvArray.append(tlv)
            }
        }
        
        let cardArrSize = cardDataArray.count
        var cardOffset: Int = 0
        while (cardOffset < cardArrSize){
            var tlv: TLV!
            do {
                tlv = try TLV(data: cardDataArray, &cardOffset)
            } catch {
                completeOperationWith(result: CardParsingResult.tlvError)
            }
            
            tlvArray.append(tlv)
        }
        
        var card = Card(tags: tlvArray)
        card.ribbonCase = checkRibbonCase(card)
        
        guard card.isWallet else {
            completeOperationWith(result: CardParsingResult.success(card))
            return
        }
        
        completeOperationWith(result: CardParsingResult.success(card))
    }
    
    func completeOperationWith(result: CardParsingResult) {
        DispatchQueue.main.async {
            self.completion(result)
        }
    }
    
}
