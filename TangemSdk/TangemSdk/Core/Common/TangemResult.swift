//
//  TangemResult.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
#if canImport(CoreNFC)
import CoreNFC
#endif

public enum TangemResult<T> {
    case success(T)
    case failure(Error)
}

public enum NFCReaderResult<T> {
    case success(T)
    case failure(NFCReaderError)
}
