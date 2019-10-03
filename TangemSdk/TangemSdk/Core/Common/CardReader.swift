//
//  CardReader.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
public protocol CardReader {
    func startSession()
    func stopSession()
    func send(command: CommandApdu, completion: @escaping (CompletionResult<ResponseApdu>) -> Void)
}
