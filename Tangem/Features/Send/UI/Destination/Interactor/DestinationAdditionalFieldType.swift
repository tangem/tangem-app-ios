//
//  SendDestinationAdditionalField.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

enum SendDestinationAdditionalField {
    case notSupported
    case empty(type: SendDestinationAdditionalFieldType)
    case filled(type: SendDestinationAdditionalFieldType, value: String, params: TransactionParams)
}

enum SendDestinationAdditionalFieldType {
    case memo
    case destinationTag

    var name: String {
        switch self {
        case .destinationTag:
            return Localization.sendDestinationTagField
        case .memo:
            return Localization.sendExtrasHintMemo
        }
    }

    static func type(for blockchain: Blockchain) -> SendDestinationAdditionalFieldType? {
        switch blockchain {
        case let value where value.hasMemo:
            return .memo
        case let value where value.hasDestinationTag:
            return .destinationTag
        default:
            return .none
        }
    }
}
