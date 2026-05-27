//
//  HederaTokenContractAddressConverter.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import struct Hiero.AccountId

public struct HederaTokenContractAddressConverter {
    public func convertFromEVMToHedera(_ evmAddress: String) throws -> String {
        // Adding the '0x' prefix just for consistency, currently the SDK can handle both prefixed and non-prefixed addresses.
        let evmAddressWithPrefix = evmAddress.addHexPrefix()

        // `fromEvmAddress(_shard:realm:)` can't be used as a drop-in replacement here for `fromSolidityAddress`
        // since it doesn't support parsing `shard` and `realm` parts.
        return try AccountId
            .fromSolidityAddress(evmAddressWithPrefix)
            .toString()
    }

    public func convertFromHederaToEVM(_ hederaAddress: String) throws -> String {
        // Since this change was implemented https://github.com/hiero-ledger/hiero-sdk-swift/pull/530, the Hedera SDK
        // can convert any EVM-like address to Hedera format by using the `AccountId.fromString` factory method.
        // This is fairly loose validation logic and it differs from the previous behavior, where conversion
        // was only possible for addresses in Hedera address format ('shard.realm.num').
        // Therefore, additional validation is required to make sure that the provided address is NOT an EVM address.
        if hederaAddress.isEvmAddress {
            throw "Expecting Hedera address ('shard.realm.num'), but EVM address received instead: \(hederaAddress)"
        }

        // `toEvmAddress()` can't be used as a drop-in replacement here for `toSolidityAddress` since it just
        // doesn't work with entities that have been created using various `shard.realm.number` constructors
        // and causes infinite recursion in such cases.
        return try AccountId
            .fromString(hederaAddress)
            .toSolidityAddress()
            .addHexPrefix()
    }

    public init() {}
}

// MARK: - Convenience extension

private extension String {
    /// (Naively) checks whether a string is an EVM address with or without the `0x` prefix.
    var isEvmAddress: Bool {
        let hexString = addHexPrefix()

        return hexString.count == 42 && hexString.dropFirst(2).allSatisfy(\.isHexDigit)
    }
}
