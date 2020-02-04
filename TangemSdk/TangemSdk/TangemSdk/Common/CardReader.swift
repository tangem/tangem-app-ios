//
//  CardReader.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import CoreNFC

/// Allows interaction between the phone or any other terminal and Tangem card.
/// Its default implementation, `NfcReader`, is in our module.
public protocol CardReader: class {
    /// For setting alertMessage into NFC popup
    var alertMessage: String {get set}
    var tagDidConnect: (() -> Void)? {get set}
    func startSession()
    func stopSession(errorMessage: String?)
    func send(commandApdu: CommandApdu, completion: @escaping (Result<ResponseApdu,NFCError>) -> Void)
    func restartPolling()
}

extension CardReader {
    func stopSession(errorMessage: String? = nil) {
        stopSession(errorMessage: nil)
    }
}

class CardReaderFactory {
    func createDefaultReader() -> CardReader {
        if #available(iOS 13.0, *) {
            return NFCReader()
        } else {
            return NDEFReader()
        }
    }
}

public enum NFCError: Error, LocalizedError {
    case stuck
    case timeout
    case readerError(underlyingError: NFCReaderError)
    
    public var errorDescription: String? {
        switch self {
        case .readerError(let nfcError):
            return nfcError.localizedDescription
        case .stuck:
            return Localization.nfcStuckError
        case .timeout:
            return Localization.nfcSessionTimeout
        }
    }
}
