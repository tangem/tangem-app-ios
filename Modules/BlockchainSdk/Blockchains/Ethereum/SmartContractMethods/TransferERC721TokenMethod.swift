//
//  TransferERC721TokenMethod.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

/// https://eips.ethereum.org/EIPS/eip-721#rationale
public struct TransferERC721TokenMethod {
    let source: SmartContractAddress
    let destination: SmartContractAddress
    let assetIdentifier: BigUInt

    public init(
        source: String,
        destination: String,
        assetIdentifier: String
    ) throws {
        guard let assetIdentifier = BigUInt(assetIdentifier) else {
            throw TransferERC721TokenMethod.Error.invalidAssetIdentifier
        }

        self.source = try SmartContractAddress(source)
        self.destination = try SmartContractAddress(destination)
        self.assetIdentifier = assetIdentifier
    }
}

// MARK: - Auxiliary types

public extension TransferERC721TokenMethod {
    enum Error: Swift.Error {
        case invalidAssetIdentifier
    }
}

// MARK: - Constants

private extension TransferERC721TokenMethod {
    enum Constants {
        static let paddingLength = 32
    }
}

// MARK: - SmartContractMethod protocol conformance

extension TransferERC721TokenMethod: SmartContractMethod {
    /// - Note: First 4 bytes of Keccak-256 hash for the `safeTransferFrom(address,address,uint256)` method.
    public var methodId: String { "0x42842e0e" }

    public var data: Data {
        let prefixData = Data(hexString: methodId)
        let sourceAddressData = source.encodedParameter
        let destinationAddressData = destination.encodedParameter
        let assetIdentifierData = assetIdentifier.serialize().leadingZeroPadding(toLength: Constants.paddingLength)

        let arguments = [
            sourceAddressData,
            destinationAddressData,
            assetIdentifierData,
        ]

        let argumentsData = arguments.reduce(into: Data(), +=)

        return prefixData + argumentsData
    }
}
