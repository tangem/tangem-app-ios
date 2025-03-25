//
//  TaprootLockingScriptBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct TaprootLockingScriptBuilder {
    private let bech32Prefix: String

    init(network: UTXONetworkParams) {
        bech32Prefix = network.bech32Prefix
    }

    func decode(address: String) throws -> (version: UInt8, script: UTXOLockingScript) {
        let bech32 = Bech32(variant: .bech32m)
        let (hrp, _) = try bech32.decode(address)

        guard hrp == bech32Prefix else {
            throw LockingScriptBuilderError.wrongBech32Prefix
        }

        let decoder = SegWitBech32(bech32: bech32)
        let (version, keyhash) = try decoder.decode(hrp: bech32Prefix, addr: address)

        let type: UTXOScriptType = switch (version, keyhash.count) {
        case (1, 32): .p2tr
        default: throw LockingScriptBuilderError.wrongAddress
        }

        let lockingScript = OpCodeUtils.p2tr(version: version, data: keyhash)
        return (version: version, script: .init(data: lockingScript, type: type))
    }
}

// MARK: - LockingScriptBuilder

extension TaprootLockingScriptBuilder: LockingScriptBuilder {
    func lockingScript(for address: String) throws -> UTXOLockingScript {
        try decode(address: address).script
    }
}
