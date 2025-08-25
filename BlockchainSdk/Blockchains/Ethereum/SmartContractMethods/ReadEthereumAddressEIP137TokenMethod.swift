//
//  ReadEthereumAddressEIP137TokenMethod.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public struct ReadEthereumAddressEIP137TokenMethod: SmartContractMethod {
    private let nameBytes: Data
    private let callDataBytes: Data

    public init(nameBytes: Data, hashBytes: Data) {
        self.nameBytes = nameBytes
        callDataBytes = Constants.readEthereumAddressInterfaceId + hashBytes
    }

    public var contractAddress: String {
        Constants.resolveEnsNameContractAddress
    }

    public var methodId: String { "0x9061b923" }

    public var data: Data {
        let prefixData = Data(hexString: methodId)

        let nameBytesOffset = Constants.nameBytes.leadingZeroPadding(toLength: 32)
        let callDataBytesOffset = Constants.callDataBytes.leadingZeroPadding(toLength: 32)
        let nameBytesLength = nameBytes.count.byte.leadingZeroPadding(toLength: 32)
        let nameBytesSized32 = nameBytes.trailingZeroPadding(toLength: 32)
        let callDataBytesLength = callDataBytes.count.byte.leadingZeroPadding(toLength: 32)

        let arguments = [
            nameBytesOffset,
            callDataBytesOffset,
            nameBytesLength,
            nameBytesSized32,
            callDataBytesLength,
            callDataBytes,
        ]

        let argumentsData = arguments.reduce(into: Data(), +=)

        return prefixData + argumentsData
    }
}

extension ReadEthereumAddressEIP137TokenMethod {
    enum Constants {
        static let nameBytes = Data(64)
        static let callDataBytes = Data(128)
        static let resolveEnsNameContractAddress = "0x64969fb44091A7E5fA1213D30D7A7e8488edf693"
        static let readEthereumAddressInterfaceId = Data(hexString: "0x3b3b57de")
    }
}
