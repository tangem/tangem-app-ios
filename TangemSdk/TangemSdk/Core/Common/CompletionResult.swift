//
//  CompletionResult.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import CoreNFC

public enum CompletionResult<TSuccess, TError> {
    case success(TSuccess)
    case failure(TError)
}

public enum CancellableCompletionResult<TSuccess, TError> {
    case success(TSuccess)
    case failure(TError)
    case userCancelled
}
