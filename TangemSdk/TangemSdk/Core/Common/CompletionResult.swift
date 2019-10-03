//
//  CompletionResult.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

public enum CompletionResult<T> {
    case success(T)
    case failure(Error)
}
