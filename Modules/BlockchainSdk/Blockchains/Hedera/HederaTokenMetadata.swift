//
//  HederaTokenMetadata.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum HederaTokenType: String, Codable {
    case hts
    case erc20
}

struct HederaTokenMetadata: Codable, Equatable {
    let type: HederaTokenType
    let contractId: String?
    let evmAddress: String?
}

struct HederaTokenMetadataResolver {
    private let networkService: HederaNetworkService
    private let addressConverter = HederaTokenContractAddressConverter()

    init(networkService: HederaNetworkService) {
        self.networkService = networkService
    }

    func resolve(contractAddress: String) async throws -> HederaTokenMetadata {
        if HederaTokenContractAddressConverter.isERC20TokenAddress(contractAddress) {
            let contractInfo = try? await networkService.getContractInfo(address: contractAddress).async()

            return HederaTokenMetadata(
                type: .erc20,
                contractId: contractInfo?.contractId,
                evmAddress: contractInfo?.evmAddress ?? contractAddress.addHexPrefix().lowercased()
            )
        }

        let normalizedAddress = normalizeHTSAddress(contractAddress)
        let tokenType = try await networkService.getTokenType(tokenAddress: normalizedAddress).async()

        switch tokenType {
        case .hts:
            return HederaTokenMetadata(type: .hts, contractId: normalizedAddress, evmAddress: nil)
        case .erc20:
            let contractInfo = try await networkService.getContractInfo(address: normalizedAddress).async()
            return HederaTokenMetadata(
                type: .erc20,
                contractId: contractInfo.contractId ?? normalizedAddress,
                evmAddress: contractInfo.evmAddress
            )
        }
    }

    func normalizeHTSAddress(_ address: String) -> String {
        guard
            HederaTokenContractAddressConverter.extractEVMAddressBody(from: address) != nil,
            !HederaTokenContractAddressConverter.isERC20TokenAddress(address)
        else {
            return address
        }

        return (try? addressConverter.convertFromEVMToHedera(address)) ?? address
    }
}
