//
//  EthereumAddressResolver.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct EthereumAddressResolver {
    private let networkService: EthereumNetworkService
    private let ensProcessor: ENSProcessor

    init(networkService: EthereumNetworkService, ensProcessor: ENSProcessor) {
        self.networkService = networkService
        self.ensProcessor = ensProcessor
    }
}

extension EthereumAddressResolver: AddressResolver {
    func resolve(_ address: String) async throws -> String {
        let nameHash = try ensProcessor.getNameHash(address)
        let encodedName = try ensProcessor.encode(name: address)
        return try await networkService.resolveAddress(hash: nameHash, encode: encodedName).async()
    }
}
