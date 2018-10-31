//
//  CardScanOperation.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Smart Cash AG. All rights reserved.
//

import Foundation
import CoreNFC

enum NFCReaderErrorCode: Int {
    case invalidatedUnexpectedly = 202
    case other
    
    init(errorCode: Int) {
        self = NFCReaderErrorCode(rawValue: errorCode) ?? .other
    }
}

struct NFCReaderError: Error {
    
    var message: String
    var code: NFCReaderErrorCode = .other
    
    init(generalError: Error) {
        self.message = generalError.localizedDescription
        self.code = NFCReaderErrorCode(errorCode: (generalError as NSError).code)
    }
    
    var localizedDescription: String {
        return message
    }
}

class CardScanner: NSObject {
    
    static let tangemWalletRecordType = "tangem.com:wallet"
    
    enum CardScannerResult {
        case pending(Card)
        case success(Card)
        case readerSessionError(NFCReaderError)
        case locked
        case tlvError
        case nonGenuineCard(Card)
    }
    
    var operationQueue = OperationQueue()
    var completion: (CardScannerResult) -> Void
    
    var session: NFCReaderSession?
    var savedCard: Card?
    
    init(completion: @escaping (CardScannerResult) -> Void) {
        self.completion = completion
    }
    
    func initiateScan(shouldCleanup: Bool = true) {
        if shouldCleanup {
            savedCard = nil
        }
        
        session = NFCNDEFReaderSession(delegate: self,
                                            queue: nil,
                                            invalidateAfterFirstRead: true)
        session?.begin()
    }
    
    func invalidate() {
        session?.invalidate()
    }
    
    func handleMessage(_ message: NFCNDEFMessage) {
        let payloads = message.records.filter { (record) -> Bool in
            guard let recordType = String(data: record.type, encoding: String.Encoding.utf8) else {
                return false
            }
            
            return recordType == CardScanner.tangemWalletRecordType
        }
        
        guard !payloads.isEmpty, let payload = payloads.first?.payload else {
            return
        }
        
        launchParsingOperationWith(payload: payload)
    }
    
    func launchParsingOperationWith(payload: Data) {
        operationQueue.cancelAllOperations()
        
        let operation = CardParsingOperation(payload: payload) { (result) in
            switch result {
            case .success(let card):
                self.handleDidParseCard(card)
            case .locked:
                self.completion(.locked)
            case .tlvError:
                self.completion(.tlvError)
            }
        }
        operationQueue.addOperation(operation)
    }
    
    func handleDidParseCard(_ card: Card) {
        
        guard var savedCard = savedCard else {
            self.savedCard = card
            initiateScan(shouldCleanup: false)
            completion(.pending(card))
            return
        }
        
        savedCard.updateWithVerificationCard(card)
        
        guard savedCard.isAuthentic else {
            completion(.nonGenuineCard(savedCard))
            return
        }
        
        completion(.success(savedCard))
    }

}

extension CardScanner: NFCNDEFReaderSessionDelegate {
    
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        DispatchQueue.main.async {
            self.completion(.readerSessionError(NFCReaderError(generalError: error)))
        }
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        messages.forEach({ self.handleMessage($0) })
    }
    
}
