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
    var isReady: Bool { get }
    var alertMessage: String {get set}
    var tagDidConnect: (() -> Void)? {get set}
    func startSession(with message: String?)
    func stopSession(with errorMessage: String?)
    func send(commandApdu: CommandApdu, completion: @escaping (Result<ResponseApdu,TaskError>) -> Void)
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

class CardReaderFactory {
    func createDefaultReader() -> CardReader {
        if #available(iOS 13.0, *) {
            return NFCReader()
        } else {
            return NDEFReader()
        }
    }
}
