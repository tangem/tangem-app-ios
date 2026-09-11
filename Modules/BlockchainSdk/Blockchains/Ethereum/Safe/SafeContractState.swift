//
//  SafeContractState.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

/// What a Safe looks like in one network.
public enum SafeContractState: Hashable {
    /// No code at the address yet: the first operation deploys it, at nonce zero.
    case notDeployed
    case deployed(nonce: Int, owners: [String], threshold: Int)

    public var isDeployed: Bool {
        switch self {
        case .notDeployed: false
        case .deployed: true
        }
    }

    /// The nonce the next operation is signed with.
    public var nonce: Int {
        switch self {
        case .notDeployed: 0
        case .deployed(let nonce, _, _): nonce
        }
    }
}
