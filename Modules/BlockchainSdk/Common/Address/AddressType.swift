//
//  AddressType.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

public indirect enum AddressType: Hashable {
    case `default`
    case legacy
    case used(AddressType, path: String)

    public var defaultLocalizedName: String {
        switch self {
        case .default:
            return Localization.addressTypeDefault
        case .used(_, let index):
            return "Used \"\(index)\""
        case .legacy:
            return Localization.addressTypeLegacy
        }
    }
}

// MARK: - Comparable

extension AddressType: Comparable {
    public static func < (lhs: AddressType, rhs: AddressType) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }

    private var sortOrder: Int {
        switch self {
        case .default: 0
        case .used: 1
        case .legacy: 2
        }
    }
}

// MARK: - AddressTypeError

public enum AddressTypeError: Error {
    case notSupported
}
