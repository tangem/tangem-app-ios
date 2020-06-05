//
//  CardReader.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import CoreNFC
import Combine

public enum NFCTagType{
    case tag(uid: Data)
    case slix2
    case unknown
}

/// Allows interaction between the phone or any other terminal and Tangem card.
/// Its default implementation, `NfcReader`, is in our module.
public protocol CardReader: class {
    /// For setting alertMessage into NFC popup
    var isReady: Bool { get }
    var alertMessage: String {get set}
    @available(iOS 13.0, *)
    var tag: CurrentValueSubject<NFCTagType?,TangemSdkError> {get}
    func startSession(with message: String?)
    func stopSession(with errorMessage: String?)
    func send(apdu: CommandApdu, completion: @escaping (Result<ResponseApdu,TangemSdkError>) -> Void)
    @available(iOS 13.0, *)
    func sendPublisher(apdu: CommandApdu) -> AnyPublisher<ResponseApdu, TangemSdkError>
    func readSlix2Tag(completion: @escaping (Result<ResponseApdu, TangemSdkError>) -> Void) 
    func restartPolling()
}

public extension CardReader {
    func startSession(with message: String? = nil) {
        startSession(with: message)
    }
    
    func stopSession(with errorMessage: String? = nil) {
        stopSession(with: errorMessage)
    }
}

public class CardReaderFactory {
    public init() {}
    
    public func createDefaultReader() -> CardReader {
        if #available(iOS 13.0, *) {
            return NFCReader()
        } else {
            return NDEFReader()
        }
    }
}
