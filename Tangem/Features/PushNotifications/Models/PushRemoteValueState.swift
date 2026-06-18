//
//  PushRemoteValueState.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum PushRemoteValueState<Value: Equatable>: Equatable {
    case loading
    case failed
    case ready(Value)
}
