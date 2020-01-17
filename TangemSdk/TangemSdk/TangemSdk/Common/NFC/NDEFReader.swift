//
//  NFCNDEFReader.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import CoreNFC

/// Provides NFC communication between an  application and Tangem card (iOS 12 and earlier)
public final class NDEFReader: NSObject {
    static let tangemWalletRecordType = "tangem.com:wallet"
    
    private var readerSession: NFCNDEFReaderSession?
    private var completion: ((Result<ResponseApdu, NFCError>) -> Void)?
}

extension NDEFReader: NFCNDEFReaderSessionDelegate {
    public func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        let nfcError = error as! NFCReaderError
        
        if nfcError.code != .readerSessionInvalidationErrorFirstNDEFTagRead {
            completion?(.failure(NFCError.readerError(underlyingError: nfcError)))
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
            return ndefPayload.payload.bytes
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
    public func startSession() {
        
    }
    
    public var alertMessage: String {
        get { return readerSession?.alertMessage ?? "" }
        set { readerSession?.alertMessage = newValue }
    }
    
    public func stopSession(errorMessage: String? = nil) {
        completion = nil
        readerSession?.invalidate()
    }
    
    public func send(commandApdu: CommandApdu, completion: @escaping (Result<ResponseApdu, NFCError>) -> Void) {
        self.completion = completion
        readerSession = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: true)
        readerSession!.alertMessage = Localization.nfcAlertDefault
        readerSession!.begin()
    }
    
    
    public func restartPolling() {
    } 
}
