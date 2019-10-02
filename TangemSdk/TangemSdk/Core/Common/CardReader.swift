//
//  CardReader.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
#if canImport(CoreNFC)
import CoreNFC
#endif

@available(iOS 13.0, *)
public protocol CardReader {
    func startSession()
    func stopSession()
    func send(command: NFCISO7816APDU, completion: @escaping (TangemResult<ResponseApdu>) -> Void)
}
