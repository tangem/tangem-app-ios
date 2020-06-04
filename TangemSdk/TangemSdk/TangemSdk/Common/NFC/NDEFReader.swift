//
//  NFCNDEFReader.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import CoreNFC
import Combine

/// Provides NFC communication between an  application and Tangem card (iOS 12 and earlier)

final class NDEFReader: NSObject {
    static let tangemWalletRecordType = "tangem.com:wallet"
    
    @available(iOS 13.0, *)
    var tag: CurrentValueSubject<NFCTagType?,TangemSdkError> {
        fatalError("Unsupported")
    }
    
    private var readerSession: NFCNDEFReaderSession?
    private var completion: ((Result<ResponseApdu, TangemSdkError>) -> Void)?
}

extension NDEFReader: NFCNDEFReaderSessionDelegate {
    
    public func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        let nfcError = error as! NFCReaderError
        
        if nfcError.code != .readerSessionInvalidationErrorFirstNDEFTagRead {
            print(nfcError.localizedDescription)
            completion?(.failure(TangemSdkError.parse(nfcError)))
        }
    }
    
    public func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        let bytes: [Byte] = messages.flatMap { message -> [NFCNDEFPayload] in
            return message.records
        }.filter{ record -> Bool in
            guard let recordType = String(data: record.type, encoding: String.Encoding.utf8) else {
                return false
            }
            
            return recordType == NDEFReader.tangemWalletRecordType
        }.flatMap { ndefPayload -> [Byte] in
            return ndefPayload.payload.toBytes
        }
        
        guard bytes.count > 2 else {
            completion?(.success(ResponseApdu(Data(), Byte(0x00), Byte(0x00))))
            return
        }
        
        let sw1 = bytes[0]
        let sw2 = bytes[1]
        let data = Data(bytes[2...])
        let responseApdu = ResponseApdu(data, sw1, sw2)
        completion?(.success(responseApdu))
    }
}

extension NDEFReader: CardReader {
    @available(iOS 13.0, *)
    func sendPublisher(apdu: CommandApdu) -> AnyPublisher<ResponseApdu, TangemSdkError> {
        assertionFailure("Not implemented")
        return Fail(error: TangemSdkError.unknownError).eraseToAnyPublisher()
    }
    
    public func readSlix2Tag(completion: @escaping (Result<ResponseApdu, TangemSdkError>) -> Void) {
        assertionFailure("Unsupported")
    }
    
    public var isReady: Bool {
        return readerSession?.isReady ?? false
    }
    
    public var alertMessage: String {
        get { return readerSession?.alertMessage ?? "" }
        set { readerSession?.alertMessage = newValue }
    }
    
    public func stopSession(with errorMessage: String? = nil) {
        completion = nil
        readerSession?.invalidate()
        readerSession = nil
    }
    
    public func send(apdu: CommandApdu, completion: @escaping (Result<ResponseApdu, TangemSdkError>) -> Void) {
        self.completion = completion
        if #available(iOS 13.0, *), readerSession != nil {
            readerSession!.restartPolling()
        } else {
            readerSession = createSession()
            readerSession!.alertMessage = Localization.nfcAlertDefault
            readerSession!.begin()
        }
        
    }
    
    public func restartPolling() {}
    
    private func createSession() -> NFCNDEFReaderSession {
        if #available(iOS 13.0, *) {
            return NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: false)
        } else {
            return NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: true)
        }
    }
}
