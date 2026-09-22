//
//  SafeInnerCallTypeParser.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Reads what a Safe inner call is: the two forms `makeSafeInnerTransferCall` produces, and nothing else.
public enum SafeInnerCallTypeParser {
    /// - Note: The token's contract is the address the Safe calls.
    public static func parse(_ call: SafeInnerCall) throws -> SafeInnerCallType {
        if call.data.isEmpty {
            guard !call.value.isZero else {
                throw Error.emptyCall
            }

            return .transfer(.coin(destination: call.to, value: call.value))
        }

        guard call.value.isZero else {
            throw Error.valueWithCalldata
        }

        guard let transfer = TransferERC20TokenMethod.parse(calldata: call.data) else {
            throw Error.unsupportedCalldata
        }

        return .transfer(.token(contractAddress: call.to, destination: transfer.destination, value: transfer.amount))
    }
}

// MARK: - Auxiliary types

public extension SafeInnerCallTypeParser {
    enum Error: Swift.Error, Equatable {
        /// Neither a value nor calldata: the Safe would call the address for nothing.
        case emptyCall
        /// A value sent along with calldata is neither of the two transfers.
        case valueWithCalldata
        /// Calldata of anything but `transfer(address,uint256)`, or a `transfer` that does not decode.
        case unsupportedCalldata
    }
}
