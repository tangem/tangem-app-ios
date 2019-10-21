//
//  CardReader.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import CoreNFC


public protocol CardReader: class {
    func startSession()
    func stopSession()
    
    @available(iOS 13.0, *)
    func send(commandApdu: CommandApdu, completion: @escaping (CompletionResult<ResponseApdu,NFCReaderError>) -> Void)
    
    @available(iOS 13.0, *)
    func restartPolling()
}
