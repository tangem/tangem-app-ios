//
//  PolymarketSessionKeyCalls.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

public enum PolymarketSessionKeyCallsError: Error, Equatable {
    case invalidAddress(String)
    case invalidValidUntil(Int)
}

public enum PolymarketSessionKeyCalls {
    public static func authorize(
        sessionKeyAddress: String,
        depositWalletAddress: String,
        now: Date
    ) throws(PolymarketSessionKeyCallsError) -> PolymarketSessionKeyGrant {
        let validUntil = Int(now.timeIntervalSince1970) + Constants.validitySeconds

        guard let validUntilSeconds = UInt64(exactly: validUntil) else {
            throw .invalidValidUntil(validUntil)
        }

        let data = try Constants.authorizeSelector + addressWord(sessionKeyAddress) + PolymarketABIWord.uint(validUntilSeconds)

        return PolymarketSessionKeyGrant(
            sessionKeyAddress: sessionKeyAddress.lowercased(),
            validUntil: Date(timeIntervalSince1970: TimeInterval(validUntilSeconds)),
            call: try makeCall(depositWalletAddress: depositWalletAddress, data: data)
        )
    }

    public static func revoke(
        sessionKeyAddress: String,
        depositWalletAddress: String
    ) throws(PolymarketSessionKeyCallsError) -> PolymarketRelayedBatch.Call {
        try makeCall(
            depositWalletAddress: depositWalletAddress,
            data: Constants.revokeSelector + addressWord(sessionKeyAddress)
        )
    }
}

// MARK: - Private implementation

private extension PolymarketSessionKeyCalls {
    static func makeCall(
        depositWalletAddress: String,
        data: String
    ) throws(PolymarketSessionKeyCallsError) -> PolymarketRelayedBatch.Call {
        guard depositWalletAddress.isEvmAddress else {
            throw .invalidAddress(depositWalletAddress)
        }

        return PolymarketRelayedBatch.Call(target: depositWalletAddress.lowercased(), data: data)
    }

    static func addressWord(_ address: String) throws(PolymarketSessionKeyCallsError) -> String {
        guard let word = PolymarketABIWord.address(address) else {
            throw .invalidAddress(address)
        }

        return word
    }

    enum Constants {
        static let authorizeSelector = "0x24017fae"
        static let revokeSelector = "0xe63f952f"
        static let validitySeconds = 180 * 24 * 60 * 60
    }
}
