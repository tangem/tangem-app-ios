//
//  Base58LockingScriptBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import struct BitcoinCore.Base58

struct Base58LockingScriptBuilder {
    private let p2pkhPrefix: UInt8
    private let p2shPrefix: UInt8

    init(network: UTXONetworkParams) {
        p2pkhPrefix = network.p2pkh
        p2shPrefix = network.p2sh
    }

    func decode(address: String) throws -> (version: UInt8, script: UTXOLockingScript) {
        let decoded = Base58.decode(address)
        guard !decoded.isEmpty else {
            throw LockingScriptBuilderError.wrongAddress
        }

        let version = decoded[0]
        // drop version and drop checksum
        let keyHash = decoded.dropFirst().dropLast(Constants.checksumLength)
        switch version {
        case p2pkhPrefix:
            let lockingStript = OpCodeUtils.p2pkh(data: keyHash)
            return (version: version, script: .init(data: lockingStript, type: .p2pkh))
        case p2shPrefix:
            let lockingStript = OpCodeUtils.p2sh(data: keyHash)
            return (version: version, script: .init(data: lockingStript, type: .p2sh))
        default:
            throw LockingScriptBuilderError.unsupportedVersion
        }
    }
}

// MARK: - LockingScriptBuilder

extension Base58LockingScriptBuilder: LockingScriptBuilder {
    func lockingScript(for address: String) throws -> UTXOLockingScript {
        try decode(address: address).script
    }
}

// MARK: - LockingScriptBuilder

extension Base58LockingScriptBuilder {
    private enum Constants {
        static let checksumLength: Int = 4
    }
}
