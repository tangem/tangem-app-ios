//
//  CardReader.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import CoreNFC

@available(iOS 13.0, *)
public protocol CardReader: class {
    func startSession()
    func stopSession()
    func send(commandApdu: CommandApdu, completion: @escaping (CompletionResult<ResponseApdu,NFCReaderError>) -> Void)
    func restartPolling()
}
