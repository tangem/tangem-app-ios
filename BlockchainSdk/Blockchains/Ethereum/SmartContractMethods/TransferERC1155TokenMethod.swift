//
//  TransferERC1155TokenMethod.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

/// https://eips.ethereum.org/EIPS/eip-1155#specification
public struct TransferERC1155TokenMethod {
    let source: String
    let destination: String
    let assetIdentifier: BigUInt
    let assetAmount: BigUInt

    public init(
        source: String,
        destination: String,
        assetIdentifier: String,
        assetAmount: BigUInt
    ) throws(TransferERC1155TokenMethod.Error) {
        guard let assetIdentifier = BigUInt(assetIdentifier) else {
            throw TransferERC1155TokenMethod.Error.invalidAssetIdentifier
        }

        self.source = source
        self.destination = destination
        self.assetIdentifier = assetIdentifier
        self.assetAmount = assetAmount
    }
}

// MARK: - Auxiliary types

public extension TransferERC1155TokenMethod {
    enum Error: Swift.Error {
        case invalidAssetIdentifier
    }
}

// MARK: - Constants

private extension TransferERC1155TokenMethod {
    enum Constants {
        static let paddingLength = 32
    }
}

// MARK: - SmartContractMethod protocol conformance

extension TransferERC1155TokenMethod: SmartContractMethod {
    /// - Note: First 4 bytes of Keccak-256 hash for the `safeTransferFrom(address,address,uint256,uint256,bytes)` method.
    public var methodId: String { "0xf242432a" }

    public var data: Data {
        let prefixData = Data(hexString: methodId)
        let sourceAddressData = Data(hexString: source).leadingZeroPadding(toLength: Constants.paddingLength)
        let destinationAddressData = Data(hexString: destination).leadingZeroPadding(toLength: Constants.paddingLength)
        let assetIdentifierData = assetIdentifier.serialize().leadingZeroPadding(toLength: Constants.paddingLength)
        let assetAmountData = assetAmount.serialize().leadingZeroPadding(toLength: Constants.paddingLength)

        let arguments = [
            sourceAddressData,
            destinationAddressData,
            assetIdentifierData,
            assetAmountData,
        ]

        let argumentsData = arguments.reduce(into: Data(), +=)
        let bytesOffset = (arguments.count + 1) * Constants.paddingLength // `+1` for the `bytesOffsetData` argument itself
        let bytesOffsetData = BigUInt(bytesOffset).serialize().leadingZeroPadding(toLength: Constants.paddingLength)
        let bytesData = Data(count: Constants.paddingLength) // We don't use `bytes` argument, therefore 32 zero bytes here

        return prefixData + argumentsData + bytesOffsetData + bytesData
    }
}
