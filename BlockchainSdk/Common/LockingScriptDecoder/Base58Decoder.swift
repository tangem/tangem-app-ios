//
//  Base58Decoder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import struct BitcoinCore.Base58

struct Base58Decoder {
    private let checksumLength: Int = 4
    private let network: UTXONetworkParams

    init(network: UTXONetworkParams) {
        self.network = network
    }

    func decode(address: String) throws -> (version: UInt8, script: UTXOLockingScript) {
        let decoded = Base58.decode(address)
        guard !decoded.isEmpty else {
            throw LockingScriptBuilderError.wrongAddress
        }

        let version = decoded[0]
        // drop version and drop checksum
        let keyHash = decoded.dropFirst().dropLast(checksumLength)
        switch version {
        case network.p2pkh:
            let lockingStript = OpCodeUtils.p2pkh(data: keyHash)
            return (version: version, script: .init(data: lockingStript, type: .p2pkh))
        case network.p2sh:
            let lockingStript = OpCodeUtils.p2sh(data: keyHash)
            return (version: version, script: .init(data: lockingStript, type: .p2sh))
        default:
            throw LockingScriptBuilderError.unsupportedVersion
        }
    }
}

// MARK: - LockingScriptBuilder

extension Base58Decoder: LockingScriptBuilder {
    func lockingScript(for address: String) throws -> UTXOLockingScript {
        try decode(address: address).script
    }
}
