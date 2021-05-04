//
//  IAddressConverter.swift
//  TangemClip
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

public class SegWitBech32AddressConverter {
    private let prefix: String
    private let scriptConverter: IScriptConverter

    public init(prefix: String, scriptConverter: IScriptConverter) {
        self.prefix = prefix
        self.scriptConverter = scriptConverter
    }

    public func convert(address: String) throws -> SegWitAddress {
        if let segWitData = try? SegWitBech32.decode(hrp: prefix, addr: address) {
            var type: BitcoinCoreAddressType = .pubKeyHash
            if segWitData.version == 0 {
                switch segWitData.program.count {
                    case 32: type = .scriptHash
                    default: break
                }
            }
            return SegWitAddress(type: type, keyHash: segWitData.program, bech32: address, version: segWitData.version)
        }
        throw BitcoinCoreErrors.AddressConversion.unknownAddressType
    }

    public func convert(keyHash: Data, type: ScriptType) throws -> SegWitAddress {
        let script = try scriptConverter.decode(data: keyHash)
        guard script.chunks.count == 2,
              let versionCode = script.chunks.first?.opCode,
              let versionByte = OpCode.value(fromPush: versionCode),
              let keyHash = script.chunks.last?.data else {
            throw BitcoinCoreErrors.AddressConversion.invalidAddressLength
        }
        let addressType: BitcoinCoreAddressType
        switch type {
            case .p2wpkh:
                addressType = BitcoinCoreAddressType.pubKeyHash
            case .p2wsh:
                addressType = BitcoinCoreAddressType.scriptHash
            default: throw BitcoinCoreErrors.AddressConversion.unknownAddressType
        }
        let bech32 = try SegWitBech32.encode(hrp: prefix, version: versionByte, program: keyHash)
        return SegWitAddress(type: addressType, keyHash: keyHash, bech32: bech32, version: versionByte)
    }

    public func convert(publicKey: BitcoinCorePublicKey, type: ScriptType) throws -> SegWitAddress {
        try convert(keyHash: OpCode.scriptWPKH(publicKey.keyHash), type: type)
    }
    
    public func convert(scriptHash: Data) throws -> SegWitAddress {
        try convert(keyHash: OpCode.scriptWPKH(scriptHash), type: .p2wsh)
    }

}

public class Base58AddressConverter {
    private static let checkSumLength = 4
    private let addressVersion: UInt8
    private let addressScriptVersion: UInt8

    public init(addressVersion: UInt8, addressScriptVersion: UInt8) {
        self.addressVersion = addressVersion
        self.addressScriptVersion = addressScriptVersion
    }

    public func convert(address: String) throws -> BitcoinCoreLegacyAddress {
        // check length of address to avoid wrong converting
        guard address.count >= 26 && address.count <= 35 else {
            throw BitcoinCoreErrors.AddressConversion.invalidAddressLength
        }

        let hex = Data(Base58.bytesFromBase58(address))
        // check decoded length. Must be 1(version) + 20(KeyHash) + 4(CheckSum)
        if hex.count != Base58AddressConverter.checkSumLength + 20 + 1 {
            throw BitcoinCoreErrors.AddressConversion.invalidAddressLength
        }
        let givenChecksum = hex.suffix(Base58AddressConverter.checkSumLength)
        let doubleSHA256 = (hex.prefix(hex.count - Base58AddressConverter.checkSumLength)).doubleSha256
        let actualChecksum = doubleSHA256.prefix(Base58AddressConverter.checkSumLength)
        guard givenChecksum == actualChecksum else {
            throw BitcoinCoreErrors.AddressConversion.invalidChecksum
        }

        let type: BitcoinCoreAddressType
        switch hex[0] {
            case addressVersion: type = BitcoinCoreAddressType.pubKeyHash
            case addressScriptVersion: type = BitcoinCoreAddressType.scriptHash
            default: throw BitcoinCoreErrors.AddressConversion.wrongAddressPrefix
        }

        let keyHash = hex.dropFirst().dropLast(4)
        return BitcoinCoreLegacyAddress(type: type, keyHash: keyHash, base58: address)
    }

    public func convert(keyHash: Data, type: BitcoinCoreScriptType) throws -> BitcoinCoreLegacyAddress {
        let version: UInt8
        let addressType: BitcoinCoreAddressType

        switch type {
            case .p2pkh, .p2pk:
                version = addressVersion
                addressType = BitcoinCoreAddressType.pubKeyHash
            case .p2sh, .p2wpkhSh:
                version = addressScriptVersion
                addressType = BitcoinCoreAddressType.scriptHash
            default: throw BitcoinCoreErrors.AddressConversion.unknownAddressType
        }

        var withVersion = (Data([version])) + keyHash
        let doubleSHA256 = withVersion.doubleSha256
        let checksum = doubleSHA256.prefix(4)
        withVersion += checksum
        let base58 = Base58.base58FromBytes(withVersion.bytes)
        return BitcoinCoreLegacyAddress(type: addressType, keyHash: keyHash, base58: base58)
    }

    public func convert(publicKey: BitcoinCorePublicKey, type: BitcoinCoreScriptType) throws -> BitcoinCoreLegacyAddress {
        let keyHash = type == .p2wpkhSh ? publicKey.scriptHashForP2WPKH : publicKey.keyHash
        return try convert(keyHash: keyHash, type: type)
    }

}

