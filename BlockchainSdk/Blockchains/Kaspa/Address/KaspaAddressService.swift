//
//  KaspaAddressService.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BitcoinCore

class KaspaAddressService {
    private let isTestnet: Bool
    private let prefix: String
    private let version: KaspaAddressComponents.KaspaAddressType = .P2PK_ECDSA

    init(isTestnet: Bool) {
        self.isTestnet = isTestnet
        // [REDACTED_TODO_COMMENT]
        prefix = isTestnet ? "kaspatest" : "kaspa"
    }

    func parse(_ address: String) throws -> KaspaAddressComponents {
        guard let (prefix, data) = CashAddrBech32.decode(address),
              !data.isEmpty,
              let firstByte = data.first,
              let type = KaspaAddressComponents.KaspaAddressType(rawValue: firstByte) else {
            throw Error.wrongAddress
        }

        return KaspaAddressComponents(
            prefix: prefix,
            type: type,
            hash: data.dropFirst()
        )
    }

    func scriptPublicKey(address: String) throws -> Data {
        let components = try parse(address)

        let startOpCode: OpCode?
        let endOpCode: OpCode

        switch components.type {
        case .P2PK_Schnorr:
            startOpCode = nil
            endOpCode = OpCode.OP_CHECKSIG
        case .P2PK_ECDSA:
            startOpCode = nil
            endOpCode = OpCode.OP_CODESEPARATOR
        case .P2SH:
            startOpCode = OpCode.OP_HASH256
            endOpCode = OpCode.OP_EQUAL
        }

        let startOpCodeData: Data
        if let startOpCode {
            startOpCodeData = startOpCode.value.data
        } else {
            startOpCodeData = Data()
        }
        let endOpCodeData = endOpCode.value.data
        let size = UInt8(components.hash.count)

        return startOpCodeData + size.data + components.hash + endOpCodeData
    }
}

// MARK: - AddressProvider

@available(iOS 13.0, *)
extension KaspaAddressService: AddressProvider {
    func makeAddress(for publicKey: Wallet.PublicKey, with addressType: AddressType) throws -> Address {
        let compressedKey = try Secp256k1Key(with: publicKey.blockchainKey).compress()
        let address = CashAddrBech32.encode(version.rawValue.data + compressedKey, prefix: prefix)
        let scriptPublicKey = try scriptPublicKey(address: address)
        return LockingScriptAddress(value: address, publicKey: publicKey, type: addressType, scriptPubKey: scriptPublicKey)
    }
}

// MARK: - AddressValidator

@available(iOS 13.0, *)
extension KaspaAddressService: AddressValidator {
    func validate(_ address: String) -> Bool {
        guard
            let components = try? parse(address),
            components.prefix == self.prefix
        else {
            return false
        }

        let validStartLetters = ["q", "p"]
        guard
            let firstAddressLetter = address.dropFirst(prefix.count + 1).first,
            validStartLetters.contains(String(firstAddressLetter))
        else {
            return false
        }

        return true
    }
}

extension KaspaAddressService {
    enum Error: LocalizedError {
        case wrongAddress

        var errorDescription: String? {
            switch self {
            case .wrongAddress: "Wrong KASPA address"
            }
        }
    }
}
