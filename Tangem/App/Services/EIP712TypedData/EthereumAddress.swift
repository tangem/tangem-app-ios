//
//  EthereumAddress.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

/// Ethereum address.
public struct EthereumAddress: Equatable {
    public static let size = 20

    /// Validates that the raw data is a valid address.
    static public func isValid(data: Data) -> Bool {
        return data.count == EthereumAddress.size
    }

    /// Raw address bytes, length 20.
    public let data: Data

    /// Creates an address with `Data`.
    ///
    /// - Precondition: data contains exactly 20 bytes
    public init?(data: Data) {
        if !EthereumAddress.isValid(data: data) {
            return nil
        }
        self.data = data
    }

    /// Creates an address with an hexadecimal string representation.
    public init?(string: String) {
        let data = Data(hexString: string)
        guard EthereumAddress.isValid(data: data) else {
            return nil
        }

        self.init(data: data)
    }

    public static func == (lhs: EthereumAddress, rhs: EthereumAddress) -> Bool {
        return lhs.data == rhs.data
    }
}
