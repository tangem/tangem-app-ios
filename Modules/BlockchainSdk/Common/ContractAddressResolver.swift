//
//  ContractAddressResolver.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public protocol ContractAddressResolver {
    func resolve(_ address: String) async throws -> ResolvedContractAddress
}

public struct ResolvedContractAddress {
    public let lookupAddress: String
    public let storageAddress: String
    public let isERC20: Bool
}

struct CommonContractAddressResolver: ContractAddressResolver {
    public func resolve(_ address: String) async throws -> ResolvedContractAddress {
        ResolvedContractAddress(lookupAddress: address, storageAddress: address, isERC20: false)
    }
}
