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
        let (version, keyHash) = try decoder.decode(hrp: bech32Prefix, addr: address)

        let type: UTXOScriptType = switch (version, keyHash.count) {
        case (Constants.version, 32): .p2tr
        default: throw LockingScriptBuilderError.wrongAddress
        }

        let lockingScript = OpCodeUtils.p2tr(version: version, data: keyHash)
        return (version: version, script: .init(data: lockingScript, type: type, spendable: .none))
    }

    func encode(publicKey: Data, type: UTXOScriptType) throws -> (address: String, script: UTXOLockingScript) {
        let keyHash = publicKey.sha256Ripemd160
        let lockingScript = switch type {
        case .p2tr:
            OpCodeUtils.p2tr(version: Constants.version, data: keyHash)
        default:
            throw LockingScriptBuilderError.unsupportedScriptType
        }

        let encoder = SegWitBech32(bech32: .init(variant: .bech32))
        let bech32StringValue = try encoder.encode(hrp: bech32Prefix, version: Constants.version, program: keyHash)

        let script = UTXOLockingScript(data: lockingScript, type: type, spendable: .publicKey(publicKey))
        return (address: bech32StringValue, script: script)
    }
}

// MARK: - LockingScriptBuilder

extension TaprootLockingScriptBuilder: LockingScriptBuilder {
    func lockingScript(for address: String) throws -> UTXOLockingScript {
        try decode(address: address).script
    }
}

extension TaprootLockingScriptBuilder {
    private enum Constants {
        static let version: UInt8 = 1
    }
}
