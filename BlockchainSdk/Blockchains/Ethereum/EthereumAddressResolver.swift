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
        guard shouldResolve(address: address) else {
            return address
        }

        let nameHash = try ensProcessor.getNameHash(address)
        let encodedName = try ensProcessor.encode(name: address)
        return try await networkService.resolveAddress(hash: nameHash, encode: encodedName).async()
    }

    func shouldResolve(address: String) -> Bool {
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
