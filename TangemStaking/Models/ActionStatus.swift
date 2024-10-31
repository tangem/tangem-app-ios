//
//  ActionStatus.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public enum ActionStatus: String, Hashable {
    case created
    case waitingForNext
    case processing
    case failed
    case success
}
