//
//  CashAddrLockingScriptBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct CashAddrLockingScriptBuilder {
    private let p2pkhPrefix: UInt8
    private let p2shPrefix: UInt8
    private let bech32Prefix: String

    init(network: UTXONetworkParams) {
        p2pkhPrefix = network.p2pkhPrefix
        p2shPrefix = network.p2shPrefix
        bech32Prefix = network.bech32Prefix
    }

    func decode(address: String) throws -> (version: UInt8, script: UTXOLockingScript) {
        guard let (prefix, data) = CashAddrBech32.decode(address) else {
            throw LockingScriptBuilderError.wrongAddress
        }

        guard prefix == bech32Prefix else {
            throw LockingScriptBuilderError.wrongBech32Prefix
        }

        let version = data[0]
        let keyHash = data.dropFirst()
        switch version {
        case AddressType.p2pkh.rawValue:
            let lockingScript = OpCodeUtils.p2pkh(data: keyHash)
            return (version: version, script: .init(data: lockingScript, type: .p2pkh, spendable: .none))
        case AddressType.p2sh.rawValue:
            let lockingScript = OpCodeUtils.p2sh(data: keyHash)
            return (version: version, script: .init(data: lockingScript, type: .p2sh, spendable: .none))
        default:
            throw LockingScriptBuilderError.unsupportedVersion
        }
    }

    func encode(redeemScript: Data, type: UTXOScriptType) throws -> (address: String, script: UTXOLockingScript) {
        let scriptHash = redeemScript.sha256Ripemd160
        return try encode(keyHash: scriptHash, type: type, spendable: .redeemScript(redeemScript))
    }

    func encode(publicKey: Data, type: UTXOScriptType) throws -> (address: String, script: UTXOLockingScript) {
        let keyHash = publicKey.sha256Ripemd160
        return try encode(keyHash: keyHash, type: type, spendable: .publicKey(publicKey))
    }

    func encode(keyHash: Data, type: UTXOScriptType, spendable: UTXOLockingScript.SpendableType) throws -> (address: String, script: UTXOLockingScript) {
        let bytes: Data = switch type {
        case .p2pkh: p2pkhPrefix.data + keyHash
        case .p2sh: p2shPrefix.data + keyHash
        default: throw LockingScriptBuilderError.unsupportedScriptType
        }

        let scriptData: Data = switch type {
        case .p2pkh: OpCodeUtils.p2pkh(data: keyHash)
        case .p2sh: OpCodeUtils.p2sh(data: keyHash)
        default: throw LockingScriptBuilderError.unsupportedScriptType
        }

        let script = UTXOLockingScript(data: scriptData, type: type, spendable: spendable)
        let address = CashAddrBech32.encode(bytes, prefix: bech32Prefix)
        return (address: address, script: script)
    }
}

// MARK: - LockingScriptBuilder

extension CashAddrLockingScriptBuilder: LockingScriptBuilder {
    func lockingScript(for address: String) throws -> UTXOLockingScript {
        try decode(address: address).script
    }
}

extension CashAddrLockingScriptBuilder {
    enum AddressType: UInt8 {
        case p2pkh = 0x00
        case p2sh = 0x08
    }
}
