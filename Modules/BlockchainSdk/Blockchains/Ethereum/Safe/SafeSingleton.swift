//
//  SafeSingleton.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

/// The Safe v1.5.0 master copy a proxy delegates to.
/// - Note: Part of the CREATE2 deployment data, so the same composition resolves to a different address under each
/// of these — see `SafeAddressUtils`.
public enum SafeSingleton: CaseIterable {
    case safe
    case safeL2

    var address: String {
        switch self {
        case .safe: "0xFf51A5898e281Db6DfC7855790607438dF2ca44b"
        case .safeL2: "0xEdd160fEBBD92E350D4D398fb636302fccd67C7e"
        }
    }
}
