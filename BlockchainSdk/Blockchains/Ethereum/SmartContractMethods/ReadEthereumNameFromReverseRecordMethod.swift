//
//  ReadEthereumNameFromReverseRecordMethod.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

/// Universal Resolver call for reverse record to get the ENS name of an address.
/// See https://docs.ens.domains/ for details about reverse resolution.
public struct ReadEthereumNameFromReverseRecordMethod: SmartContractMethod {
    private let normalizedAddress: String

    public init(address: String) {
        let normalizedAddress = address.lowercased().removeHexPrefix()
        self.normalizedAddress = normalizedAddress
    }

    public var contractAddress: String {
        Constants.universalResolver
    }

    public var methodId: String { "0x5d78a217" }

    public var data: Data {
        let prefixData = Data(hexString: methodId)

        let addressData = Data(hexString: normalizedAddress)

        // Chain ID for Ethereum mainnet (60)
        let chainId = Data(hexString: Constants.chainId)

        let addressLength = Data(hexString: Constants.addressLength)

        // Offset to bytes data (64 bytes = 0x40 in hex)
        let offsetToBytes = Data(hexString: Constants.offsetToBytes)

        // Combine all parts
        let argumentsData = offsetToBytes + chainId + addressLength + addressData

        return prefixData + argumentsData
    }
}

extension ReadEthereumNameFromReverseRecordMethod {
    enum Constants {
        /// Chain ID for Ethereum mainnet (60)
        static let chainId = "000000000000000000000000000000000000000000000000000000000000003c"
        /// Address length (20 bytes = 32 in hex)
        static let addressLength = "0000000000000000000000000000000000000000000000000000000000000014"
        /// Offset to bytes data (64 bytes = 0x40 in hex)
        static let offsetToBytes = "0000000000000000000000000000000000000000000000000000000000000040"

        static let universalResolver = "0x64969fb44091A7E5fA1213D30D7A7e8488edf693"
    }
}
