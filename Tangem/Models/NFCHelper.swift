//
//  NFCHelper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Yulia Moskaleva. All rights reserved.
//

import Foundation
import CoreNFC

protocol NFCHelperDelegate {
    
    func nfcHelper(_ helper: NFCHelper, didInvalidateWith error: Error)
    func nfcHelper(_ helper: NFCHelper, didDetectCardWith hexPayload: String)
    
}

class NFCHelper: NSObject, NFCNDEFReaderSessionDelegate {
    
    var delegate: NFCHelperDelegate?
    var session: NFCReaderSession?
    
    func restartSession() {
        self.session = NFCNDEFReaderSession(delegate: self,
                                           queue: nil,
                                           invalidateAfterFirstRead: true)
        self.session?.begin()
    }
    
    // MARK: NFCNDEFReaderSessionDelegate
    
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        self.delegate?.nfcHelper(self, didInvalidateWith: error)
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        for message in messages {
            var recordsCounter = 0
            
            for record in message.records {
                recordsCounter += 1
                print("Payload: \(record.payload)")
                
                var hexPayload = ""
                
                for byte in record.payload{
                    hexPayload += byte.toAsciiHex()
                }
                
                if recordsCounter == 3 {
                    self.delegate?.nfcHelper(self, didDetectCardWith: hexPayload)
                }
            }
        }
    }
}

