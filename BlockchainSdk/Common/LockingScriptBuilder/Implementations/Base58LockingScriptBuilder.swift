//
//  Base58LockingScriptBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct Base58LockingScriptBuilder {
    private let p2pkhPrefix: UInt8
    private let p2shPrefix: UInt8

    init(network: UTXONetworkParams) {
        p2pkhPrefix = network.p2pkhPrefix
        p2shPrefix = network.p2shPrefix
    }

    func decode(address: String) throws -> (version: UInt8, script: UTXOLockingScript) {
        let decoded = Base58.decode(address)
        guard decoded.count == Constants.decodedLength else {
            throw LockingScriptBuilderError.wrongAddress
        }

        let checksum = decoded.suffix(Constants.checksumLength)
        let calculatedChecksum = decoded.dropLast(Constants.checksumLength).sha256().sha256().prefix(Constants.checksumLength)
        guard checksum == calculatedChecksum else {
            throw LockingScriptBuilderError.wrongChecksum
        }

        let version = decoded[0]

        // drop version and drop checksum
        let keyHash = decoded.dropFirst().dropLast(Constants.checksumLength)

        switch version {
        case p2pkhPrefix:
            let lockingScript = OpCodeUtils.p2pkh(data: keyHash)
            return (version: version, script: .init(keyHash: keyHash, data: lockingScript, type: .p2pkh))
        case p2shPrefix:
            let lockingScript = OpCodeUtils.p2sh(data: keyHash)
            // We don't have redeemScript from address. Only from PublicKey
            return (version: version, script: .init(keyHash: keyHash, data: lockingScript, type: .p2sh(redeemScript: nil)))
        default:
            throw LockingScriptBuilderError.unsupportedVersion
        }
    }

    func encode(publicKey: Data, type: UTXOScriptType) throws -> (address: String, script: UTXOLockingScript) {
        let keyHash = publicKey.sha256Ripemd160
        return try encode(keyHash: keyHash, type: type)
    }

    func encode(keyHash: Data, type: UTXOScriptType) throws -> (address: String, script: UTXOLockingScript) {
        let script: UTXOLockingScript
        var bytes = Data()

        switch type {
        case .p2pkh:
            bytes.append(p2pkhPrefix)
            bytes.append(keyHash)

            script = .init(keyHash: keyHash, data: OpCodeUtils.p2pkh(data: keyHash), type: type)
        case .p2sh:
            bytes.append(p2shPrefix)
            bytes.append(keyHash)

            script = .init(keyHash: keyHash, data: OpCodeUtils.p2sh(data: keyHash), type: type)
        default:
            throw LockingScriptBuilderError.unsupportedScriptType
        }

        let checksum = bytes.sha256().sha256().prefix(4)
        bytes += checksum
        let base58StringValue = Base58.encode(bytes)

        return (address: base58StringValue, script: script)
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
        // Must be 1(version) + 20(KeyHash) + 4(CheckSum)
        static let decodedLength: Int = 25
        static let checksumLength: Int = 4
    }
}
