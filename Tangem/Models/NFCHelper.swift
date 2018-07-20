//
//  NFCHelper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Yulia Moskaleva. All rights reserved.
//

import Foundation
import CoreNFC

class NFCHelper: NSObject, NFCNDEFReaderSessionDelegate {
    var onNFCResult: ((Bool, String) -> ())?
    var session: NFCReaderSession?
    func restartSession() {
        self.session = NFCNDEFReaderSession(delegate: self,
                                           queue: nil,
                                           invalidateAfterFirstRead: true)
        self.session?.begin()
    }
    
    // MARK: NFCNDEFReaderSessionDelegate
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        guard let onNFCResult = onNFCResult else { return }
        onNFCResult(false, error.localizedDescription)
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        guard let onNFCResult = onNFCResult else { return }
        for message in messages {
            var recordsCounter = 0
            for record in message.records {
                recordsCounter += 1
                print("Payload: \(record.payload)")
                let paylod = record.payload
                var hexPayload = ""
                
                for byte in paylod{
                    hexPayload += byte.toAsciiHex()
                }
                if recordsCounter == 3 {
                    onNFCResult(true, hexPayload)
                    
                }
//                print("Hex Payload: \(hexPayload)")
//                if let resultString = String(data: record.payload, encoding: .utf8) {
//                    onNFCResult(true, resultString)
//                }
            }
        }
    }
}

