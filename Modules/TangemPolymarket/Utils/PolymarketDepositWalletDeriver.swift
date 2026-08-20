//
//  PolymarketDepositWalletDeriver.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import CryptoSwift
import TangemFoundation

public enum PolymarketDepositWalletDeriver {
    public static func derive(ownerAddress: String) throws(PolymarketDepositWalletError) -> String {
        guard ownerAddress.isEvmAddress, let owner = bytes(from: ownerAddress) else {
            throw .invalidOwnerAddress
        }

        let factory = try contractBytes(from: PolymarketDepositWalletContracts.factory)
        let arguments = leftPaddedWord(factory) + leftPaddedWord(owner)

        let initCode = try contractBytes(from: PolymarketDepositWalletContracts.beaconInitPrefix)
            + contractBytes(from: PolymarketDepositWalletContracts.beacon)
            + contractBytes(from: PolymarketDepositWalletContracts.beaconInitSuffix)
            + arguments

        let create2 = ([Constants.create2Prefix] + factory + arguments.sha3(.keccak256) + initCode.sha3(.keccak256))
            .sha3(.keccak256)

        return checksummed(Array(create2.suffix(Constants.addressLength)))
    }
}

// MARK: - Private implementation

private extension PolymarketDepositWalletDeriver {
    enum Constants {
        static let addressLength = 20
        static let wordLength = 32
        static let checksumThreshold = 8
        static let create2Prefix: UInt8 = 0xff
    }

    static func bytes(from hex: String) -> [UInt8]? {
        let digits = Array(hex.removeHexPrefix())

        guard digits.count.isMultiple(of: 2) else {
            return nil
        }

        var bytes = [UInt8]()
        bytes.reserveCapacity(digits.count / 2)

        for index in stride(from: 0, to: digits.count, by: 2) {
            let pair = digits[index ... index + 1]

            guard pair.allSatisfy(\.isHexDigit), let byte = UInt8(String(pair), radix: 16) else {
                return nil
            }

            bytes.append(byte)
        }

        return bytes
    }

    static func contractBytes(from hex: String) throws(PolymarketDepositWalletError) -> [UInt8] {
        guard let bytes = bytes(from: hex) else {
            throw .invalidContractConstant
        }

        return bytes
    }

    static func leftPaddedWord(_ bytes: [UInt8]) -> [UInt8] {
        Array(repeating: 0, count: max(0, Constants.wordLength - bytes.count)) + bytes
    }

    static func checksummed(_ address: [UInt8]) -> String {
        let lowercased = address.toHexString()
        let hash = Array(lowercased.utf8).sha3(.keccak256).toHexString()

        let characters = zip(lowercased, hash).map { character, hashCharacter -> Character in
            guard let digit = hashCharacter.hexDigitValue, digit >= Constants.checksumThreshold else {
                return character
            }

            return Character(character.uppercased())
        }

        return String(characters).addHexPrefix()
    }
}
