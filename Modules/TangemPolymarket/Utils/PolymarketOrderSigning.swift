//
//  PolymarketOrderSigning.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import CryptoSwift
import TangemFoundation
import TangemSdk

public enum PolymarketOrderSigningError: Error, Equatable {
    case invalidAddress(String)
    case invalidWord(String)
    case invalidAmount(String)
    case invalidSignatureType(Int)
}

public enum PolymarketOrderSigning {
    public static func digest(
        order: PolymarketOrder,
        domain: PolymarketExchangeDomain,
        depositWalletAddress: String
    ) throws(PolymarketOrderSigningError) -> Data {
        let parts: [Data] = try [
            typedDataSignTypeHash(),
            hashStruct(order),
            keccak(Data(Constants.walletDomainName.utf8)),
            keccak(Data(Constants.walletDomainVersion.utf8)),
            word(PolymarketExchange.chainId),
            addressWord(depositWalletAddress),
            Data(count: Constants.wordSize),
        ]

        let parent = keccak(concat(parts))
        let outer: [Data] = try [Constants.eip191Prefix, domainSeparator(domain), parent]

        return keccak(concat(outer))
    }

    public static func wrap(
        signature: String,
        order: PolymarketOrder,
        domain: PolymarketExchangeDomain
    ) throws(PolymarketOrderSigningError) -> String {
        let description = Data(Constants.orderType.utf8)

        let parts: [Data] = try [
            domainSeparator(domain),
            hashStruct(order),
            description,
            lengthSuffix(description.count),
        ]

        let suffix = concat(parts).hexString.lowercased()

        return (signature.removeHexPrefix().lowercased() + suffix).addHexPrefix()
    }
}

// MARK: - Hashing

private extension PolymarketOrderSigning {
    static func domainSeparator(_ domain: PolymarketExchangeDomain) throws(PolymarketOrderSigningError) -> Data {
        let parts: [Data] = try [
            keccak(Data(Constants.domainType.utf8)),
            keccak(Data(PolymarketExchange.domainName.utf8)),
            keccak(Data(domain.version.utf8)),
            word(PolymarketExchange.chainId),
            addressWord(domain.address),
        ]

        return keccak(concat(parts))
    }

    static func hashStruct(_ order: PolymarketOrder) throws(PolymarketOrderSigningError) -> Data {
        let parts: [Data] = try [
            keccak(Data(Constants.orderType.utf8)),
            word(order.salt),
            addressWord(order.maker),
            addressWord(order.signer),
            word(decimalString: order.tokenId),
            word(decimalString: order.makerAmount),
            word(decimalString: order.takerAmount),
            word(order.side.wireValue),
            uint8Word(order.signatureType),
            word(order.timestampMillis),
            bytes32Word(order.metadata),
            bytes32Word(order.builder),
        ]

        return keccak(concat(parts))
    }

    static func uint8Word(_ value: Int) throws(PolymarketOrderSigningError) -> Data {
        guard let byte = UInt8(exactly: value) else {
            throw .invalidSignatureType(value)
        }

        return word(UInt64(byte))
    }

    static func typedDataSignTypeHash() -> Data {
        keccak(Data((Constants.typedDataSignType + Constants.orderType).utf8))
    }

    static func concat(_ parts: [Data]) -> Data {
        parts.reduce(into: Data()) { $0.append($1) }
    }

    static func keccak(_ data: Data) -> Data {
        Data(SHA3(variant: .keccak256).calculate(for: data.bytes))
    }
}

// MARK: - Unsigned integers

extension PolymarketOrderSigning {
    static func word(decimalString value: String) throws(PolymarketOrderSigningError) -> Data {
        guard !value.isEmpty, value.allSatisfy(\.isASCIIDigit) else {
            throw .invalidAmount(value)
        }

        var digits = Array(value.compactMap(\.wholeNumberValue).drop { $0 == 0 })
        var bytes: [UInt8] = []

        while !digits.isEmpty {
            var remainder = 0
            var quotient: [Int] = []

            for digit in digits {
                let current = remainder * 10 + digit
                quotient.append(current / Constants.base)
                remainder = current % Constants.base
            }

            bytes.insert(UInt8(remainder), at: 0)
            digits = Array(quotient.drop { $0 == 0 })
        }

        guard bytes.count <= Constants.wordSize else {
            throw .invalidAmount(value)
        }

        return Data(count: Constants.wordSize - bytes.count) + Data(bytes)
    }
}

// MARK: - Word encoding

private extension PolymarketOrderSigning {
    static func word(_ value: UInt64) -> Data {
        var bytes = Data(count: Constants.wordSize - MemoryLayout<UInt64>.size)
        bytes.append(contentsOf: withUnsafeBytes(of: value.bigEndian, Array.init))

        return bytes
    }

    static func hexBytes(_ value: String, byteCount: Int) -> Data? {
        var digits = Substring(value)

        if digits.prefix(Constants.hexPrefix.count).lowercased() == Constants.hexPrefix {
            digits = digits.dropFirst(Constants.hexPrefix.count)
        }

        guard digits.count == 2 * byteCount, digits.allSatisfy(\.isASCIIHexDigit) else {
            return nil
        }

        return Data(hexString: String(digits))
    }

    static func addressWord(_ address: String) throws(PolymarketOrderSigningError) -> Data {
        guard let bytes = hexBytes(address, byteCount: Constants.addressSize) else {
            throw .invalidAddress(address)
        }

        return Data(count: Constants.wordSize - Constants.addressSize) + bytes
    }

    static func bytes32Word(_ value: String) throws(PolymarketOrderSigningError) -> Data {
        guard let bytes = hexBytes(value, byteCount: Constants.wordSize) else {
            throw .invalidWord(value)
        }

        return bytes
    }

    static func lengthSuffix(_ length: Int) -> Data {
        Data([UInt8(truncatingIfNeeded: length >> 8), UInt8(truncatingIfNeeded: length)])
    }
}

// MARK: - Constants

private extension PolymarketOrderSigning {
    enum Constants {
        static let wordSize = 32
        static let addressSize = 20
        static let base = 256
        static let hexPrefix = "0x"

        static let eip191Prefix = Data([0x19, 0x01])

        static let walletDomainName = PolymarketDepositWalletDomain.name
        static let walletDomainVersion = PolymarketDepositWalletDomain.version

        static let domainType = "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"

        static let orderType = "Order(uint256 salt,address maker,address signer,uint256 tokenId,"
            + "uint256 makerAmount,uint256 takerAmount,uint8 side,uint8 signatureType,uint256 timestamp,"
            + "bytes32 metadata,bytes32 builder)"

        static let typedDataSignType = "TypedDataSign(Order contents,string name,string version,uint256 chainId,"
            + "address verifyingContract,bytes32 salt)"
    }
}

// MARK: - Private extensions

private extension Character {
    var isASCIIDigit: Bool {
        isASCII && isNumber
    }

    var isASCIIHexDigit: Bool {
        isASCII && isHexDigit
    }
}
