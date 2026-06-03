//
//  HederaContractAddressResolver.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Hiero
import TangemFoundation

struct HederaContractAddressResolver: ContractAddressResolver {
    let isTestnet: Bool
    let networkService: HederaNetworkService
    private let addressValidator: HederaAddressValidator

    init(isTestnet: Bool, networkService: HederaNetworkService) {
        self.isTestnet = isTestnet
        self.networkService = networkService
        addressValidator = HederaAddressValidator(isTestnet: isTestnet)
    }

    public func resolve(_ address: String) async throws -> ResolvedContractAddress {
        let normalizedAddress = address.trimmed()

        // Keep plain Hedera IDs as-is, but do not short-circuit EVM-formatted addresses.
        // Otherwise zero-prefixed EVM values (0x000...04d2) are treated as final and skip conversion to 0.0.1234.
        if normalizedAddress.contains("."), isValidHederaAddress(normalizedAddress) {
            return ResolvedContractAddress(
                lookupAddress: normalizedAddress,
                storageAddress: normalizedAddress,
                isERC20: false
            )
        }

        guard let evmAddressBody = HederaTokenContractAddressConverter.extractEVMAddressBody(from: normalizedAddress) else {
            throw ResolutionError.invalidAddress(line: #line)
        }

        if HederaTokenContractAddressConverter.hasZeroFirstTenBytes(evmAddressBody) {
            guard let intValue = evmAddressBody.hexToInt() else {
                throw ResolutionError.invalidAddress(line: #line)
            }

            let hederaAddress = "0.0.\(intValue)"

            guard isValidHederaAddress(hederaAddress) else {
                throw ResolutionError.invalidHederaAddress
            }

            return ResolvedContractAddress(
                lookupAddress: hederaAddress,
                storageAddress: hederaAddress,
                isERC20: false
            )
        }

        guard let contractId = try await fetchContractId(for: normalizedAddress) else {
            throw ResolutionError.missingContractId
        }

        guard isValidHederaAddress(contractId) else {
            throw ResolutionError.invalidHederaAddress
        }

        return ResolvedContractAddress(
            lookupAddress: contractId,
            storageAddress: evmAddressBody.addHexPrefix(),
            isERC20: true
        )
    }
}

// MARK: - Private

private extension HederaContractAddressResolver {
    func isValidHederaAddress(_ address: String) -> Bool {
        addressValidator.isValid(address: address)
    }

    func fetchContractId(for evmAddress: String) async throws -> String? {
        try await networkService.getContractId(evmAddress: evmAddress).async()
    }
}

extension HederaContractAddressResolver {
    enum ResolutionError: LocalizedError, Equatable {
        case invalidAddress(line: UInt)
        case invalidHederaAddress
        case missingContractId

        var errorDescription: String? {
            switch self {
            case .invalidAddress(let line):
                return "Invalid Hedera contract address at line \(line)"
            case .invalidHederaAddress:
                return "Invalid Hedera contract address"
            case .missingContractId:
                return "Hedera contract ID is missing in RPC response"
            }
        }
    }
}
