//
//  StakingTargetSummary.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct StakingTargetSummary: Hashable, Sendable {
    public let network: StakingNetworkType
    public let address: String
    public let name: String

    public init(network: StakingNetworkType, address: String, name: String) {
        self.network = network
        self.address = address
        self.name = name
    }
}

// MARK: - Auxiliary types

public extension StakingTargetSummary {
    struct ID: Hashable, Sendable {
        public let network: StakingNetworkType
        public let address: String

        public init(network: StakingNetworkType, address: String) {
            self.network = network
            self.address = address
        }
    }
}

// MARK: - Identifiable protocol conformance

extension StakingTargetSummary: Identifiable {
    public var id: ID {
        ID(network: network, address: address)
    }
}
