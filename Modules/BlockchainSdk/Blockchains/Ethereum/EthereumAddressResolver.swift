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
    func resolve(_ address: String) async throws -> AddressResolverResult {
        guard requiresResolution(address: address) else {
            return AddressResolverResult(resolved: address)
        }

        let nameHash = try ensProcessor.getNameHash(address)
        let encodedName = try ensProcessor.encode(name: address)
        let resolved = try await networkService.resolveAddress(hash: nameHash, encode: encodedName).async()
        return AddressResolverResult(resolved: resolved)
    }

    func requiresResolution(address: String) -> Bool {
        !EthereumAddressUtils.isValidAddressHex(value: address)
    }
}

extension EthereumAddressResolver: DomainNameAddressResolver {
    func resolveDomainName(_ address: String) async throws -> String {
        // Reverse ENS: input is a hex address, output is a domain name
        guard EthereumAddressUtils.isValidAddressHex(value: address) else {
            throw ETHError.invalidSourceAddress
        }

        return try await networkService.resolveDomainName(address: address).async()
    }
}
