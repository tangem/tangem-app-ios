//
//  VersionedMessageError+.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import SolanaSwift

extension VersionedMessageError: @retroactive LocalizedError {}

extension VersionedMessageError: @retroactive UniversalError {
    public var errorCode: Int {
        switch self {
        case .expectedVersionedMessageButReceivedLegacyMessage:
            return 102010001
        case .invalidMessageVersion:
            return 102010002
        case .deserializationError:
            return 102010003
        case .other:
            return 102010004
        }
    }
}
