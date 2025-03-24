//
//  SegWitLockingScriptBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct SegWitLockingScriptBuilder {
    private let bech32Prefix: String

    init(network: UTXONetworkParams) {
        bech32Prefix = network.bech32
    }

    func decode(address: String) throws -> (version: UInt8, script: UTXOLockingScript) {
        let (hrp, checksum) = try Bech32().decode(address, withChecksumValidation: false)
        let version = checksum[0]

        guard hrp == bech32Prefix else {
            throw LockingScriptBuilderError.wrongBech32Prefix
        }

        let bech32Variant: Bech32.Variant = switch version {
        case 0: .bech32
        case 1: .bech32m
        default: throw LockingScriptBuilderError.unsupportedVersion
        }

        let bech32 = Bech32(variant: bech32Variant)
        let (v, keyhash) = try SegWitBech32(bech32: bech32)
            .decode(hrp: bech32Prefix, addr: address)

        // Just double check
        assert(v == version)

        let lockingScript = OpCodeUtils.p2wpkh(version: version, data: keyhash)

        let type: UTXOScriptType = switch (version, keyhash.count) {
        case (0, 20): .p2wpkh
        case (0, 32): .p2wsh
        case (1, 32): .p2tr
        default: throw LockingScriptBuilderError.wrongAddress
        }

        return (version: version, script: .init(data: lockingScript, type: type))
    }
}

// MARK: - LockingScriptBuilder

extension SegWitLockingScriptBuilder: LockingScriptBuilder {
    func lockingScript(for address: String) throws -> UTXOLockingScript {
        try decode(address: address).script
    }
}
