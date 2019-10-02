//
//  TangemResult.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

public enum TangemResult<T> {
    case success(T)
    case failure(Error)
}
