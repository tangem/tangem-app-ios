////
////  CardScanOperation.swift
////  Tangem
////
////  Created by [REDACTED_AUTHOR]
////  Copyright © 2018 Smart Cash AG. All rights reserved.
////
//
//import Foundation
//#if canImport(CoreNFC)
//    import CoreNFC
//#endif
//
//public class CardScanner: NSObject {
//    
//    public static  var isNFCAvailable: Bool {
//        #if targetEnvironment(simulator)
//        return true
//        #elseif canImport(CoreNFC)
//        if NSClassFromString("NFCNDEFReaderSession") == nil { return false }
//        return NFCNDEFReaderSession.readingAvailable
//        #else
//        return false
//        #endif
//    }
//
//    static let tangemWalletRecordType = "tangem.com:wallet"
//
//    public private(set) var isBusy: Bool = false
//    
//    enum CardScannerResult {
//        case pending(CardViewModel)
//        case finished(CardViewModel)
//        case readerSessionError(NFCReaderError)
//        case locked
//        case cardChanged
//        case tlvError
//    }
//
//    var operationQueue = OperationQueue()
//    var completion: (CardScannerResult) -> Void
//
//    var session: NFCReaderSession?
//    var savedCard: CardViewModel?
//
//    init(payload: Data? = nil, completion: @escaping (CardScannerResult) -> Void) {
//        self.completion = completion
//
//        super.init()
//
//        if let payload = payload {
//            launchSimulationParsingOperationWith(payload: payload)
//        } else {
//            initiateScan()
//        }
//    }
//
//    func initiateScan(shouldCleanup: Bool = true) {
//        isBusy = true
//        if shouldCleanup {
//            savedCard = nil
//        }
//        
//        session = NFCNDEFReaderSession(delegate: self,
//                                       queue: nil,
//                                       invalidateAfterFirstRead: true)
//        session?.alertMessage = "Hold the Tangem card on the upper back of your iPhone as shown above."
//        session?.begin()
//    }
//
//    func invalidate() {
//        session?.invalidate()
//    }
//
//    func handleMessage(_ message: NFCNDEFMessage) {
//        let payloads = message.records.filter { (record) -> Bool in
//            guard let recordType = String(data: record.type, encoding: String.Encoding.utf8) else {
//                return false
//            }
//
//            return recordType == CardScanner.tangemWalletRecordType
//        }
//
//        guard !payloads.isEmpty, let payload = payloads.first?.payload else {
//            return
//        }
//
//        launchParsingOperationWith(payload: payload)
//    }
//
//    func launchParsingOperationWith(payload: Data) {
//        operationQueue.cancelAllOperations()
//
//        let operation = CardParsingOperation(payload: payload) { (result) in
//            switch result {
//            case .success(let card):
//                self.handleDidParseCard(card)
//            case .locked:
//                self.completion(.locked)
//            case .tlvError:
//                self.completion(.tlvError)
//            }
//        }
//        operationQueue.addOperation(operation)
//    }
//
//    func handleDidParseCard(_ card: CardViewModel) {
//
//        guard let savedCard = savedCard else {
//            self.savedCard = card
//            initiateScan(shouldCleanup: false)
//            completion(.pending(card))
//            return
//        }
//
//        guard savedCard.cardID == card.cardID else {
//            completion(.cardChanged)
//            return
//        }
//
//        savedCard.updateWithVerificationCard(card)
//        savedCard.invalidateSignedHashes(with: card)
//        
//        completion(.finished(savedCard))
//    }
//}
//
//extension CardScanner: NFCNDEFReaderSessionDelegate {
//
//    public func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
//        isBusy = false
//            let nfcError = NFCReaderError(_nsError: error as NSError)
//            guard nfcError.code != .readerSessionInvalidationErrorFirstNDEFTagRead,
//                nfcError.code != .readerSessionInvalidationErrorUserCanceled else {
//                    return
//            }
//            print(nfcError)
//            self.completion(.readerSessionError(nfcError))
//    }
//
//    public func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
//        messages.forEach({ self.handleMessage($0) })
//    }
//    
//    public func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {
//        print("readerSessionDidBecomeActive") //silence ios 13 warning
//    }
//}
//
//extension CardScanner {
//
//    func launchSimulationParsingOperationWith(payload: Data) {
//        operationQueue.cancelAllOperations()
//
//        let operation = CardParsingOperation(payload: payload) {[weak self] (result) in
//            switch result {
//            case .success(let card):
//                card.genuinityState = .genuine
//                self?.completion(.finished(card))
//            case .locked:
//                self?.completion(.locked)
//            case .tlvError:
//                self?.completion(.tlvError)
//            }
//             self?.isBusy = false
//        }
//        operationQueue.addOperation(operation)
//    }
//
//}
