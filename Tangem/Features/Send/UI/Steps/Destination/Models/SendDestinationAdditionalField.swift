//
//  SendDestinationAdditionalField.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import BlockchainSdk

enum SendDestinationAdditionalField {
    case notSupported
    case empty(type: SendDestinationAdditionalFieldType)
    case filled(type: SendDestinationAdditionalFieldType, value: String, params: TransactionParams)

    var extraId: String? {
        switch self {
        case .notSupported, .empty: nil
        case .filled(_, let value, _): value
        }
    }

    static func field(for blockchain: Blockchain) -> SendDestinationAdditionalField {
        switch SendDestinationAdditionalFieldType.type(for: blockchain) {
        case .none:
            return .notSupported
        case .some(let type):
            return .empty(type: type)
        }
    }
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
