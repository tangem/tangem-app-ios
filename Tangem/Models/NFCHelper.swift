//
//  NFCHelper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Smart Cash AG. All rights reserved.
//

import Foundation
import CoreNFC

protocol NFCHelperDelegate {
    
    func nfcHelper(_ helper: NFCHelper, didInvalidateWith error: Error)
    func nfcHelper(_ helper: NFCHelper, didDetectCardWith payload: Data)
    
}

class NFCHelper: NSObject, NFCNDEFReaderSessionDelegate {
    
    static let tangemWalletRecordType = "tangem.com:wallet"
    
    var delegate: NFCHelperDelegate?
    var session: NFCReaderSession?
    
    func restartSession() {
        self.session = NFCNDEFReaderSession(delegate: self,
                                           queue: nil,
                                           invalidateAfterFirstRead: true)
        self.session?.begin()
    }
    
    func handleMessage(_ message: NFCNDEFMessage) {
        let payloads = message.records.filter { (record) -> Bool in
            guard let recordType = String(data: record.type, encoding: String.Encoding.utf8) else {
                return false
            }
            
            return recordType == NFCHelper.tangemWalletRecordType
        }
        
        guard !payloads.isEmpty else {
            return
        }
        
        for record in payloads {
            self.delegate?.nfcHelper(self, didDetectCardWith: record.payload)
        }
    }
    
    // MARK: NFCNDEFReaderSessionDelegate
    
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        self.delegate?.nfcHelper(self, didInvalidateWith: error)
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        messages.forEach({ self.handleMessage($0) })
    }
}

