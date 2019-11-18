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
    
    func startSession()
    func stopSession()
    func stopSession(errorMessage: String)
    func send(commandApdu: CommandApdu, completion: @escaping (Result<ResponseApdu,NFCReaderError>) -> Void)
    func restartPolling()
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
