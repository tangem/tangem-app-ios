//
//  CollectiblesPreparedTransaction.swift
//  TangemCollectibles
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import SolanaSwift

struct CollectiblesPreparedTransaction {
    let transactionID: Data
    let signatures: [Data]
    let message: Data
    let header: Header
    let accountKeys: [Data]
    let instructions: [Instruction]

    var signers: [Data] {
        Array(accountKeys.prefix(header.requiredSignatures))
    }

    func isWritable(_ index: Int) -> Bool {
        guard index >= header.requiredSignatures else {
            return index < header.requiredSignatures - header.readonlySigned
        }

        let writableUnsignedCount = accountKeys.count - header.requiredSignatures - header.readonlyUnsigned
        return index - header.requiredSignatures < writableUnsignedCount
    }
}

// MARK: - Parsing

extension CollectiblesPreparedTransaction {
    init(serialized: Data) throws {
        var reader = BinaryReader(bytes: [UInt8](serialized))
        let signatureCount = try Self.readLength(from: &reader)
        let signatures = try (0 ..< signatureCount).map { _ in
            Data(try reader.read(count: Constants.signatureLength))
        }
        let message = Data(serialized.dropFirst(serialized.count - reader.remainBytes))

        let prefix = try reader.read()
        let isVersioned = prefix & Constants.versionedMessageMask != 0

        guard !isVersioned || prefix & ~Constants.versionedMessageMask == Constants.supportedMessageVersion else {
            throw ParsingError.unsupportedMessageVersion
        }

        let requiredSignatures = try isVersioned ? reader.read() : prefix
        let header = Header(
            requiredSignatures: Int(requiredSignatures),
            readonlySigned: Int(try reader.read()),
            readonlyUnsigned: Int(try reader.read())
        )
        let accountCount = try Self.readLength(from: &reader)
        let accountKeys = try (0 ..< accountCount).map { _ in
            Data(try reader.read(count: Constants.publicKeyLength))
        }
        _ = try reader.read(count: Constants.blockhashLength)
        let instructionCount = try Self.readLength(from: &reader)
        let instructions = try (0 ..< instructionCount).map { _ in
            try Self.readInstruction(from: &reader)
        }

        if isVersioned, try Self.readLength(from: &reader) != 0 {
            throw ParsingError.addressTableLookups
        }

        guard reader.remainBytes == 0 else {
            throw ParsingError.trailingBytes
        }

        guard let transactionID = signatures.first else {
            throw ParsingError.missingSignatures
        }

        self.init(
            transactionID: transactionID,
            signatures: signatures,
            message: message,
            header: header,
            accountKeys: accountKeys,
            instructions: instructions
        )

        try validate()
    }
}

// MARK: - Header

extension CollectiblesPreparedTransaction {
    struct Header {
        let requiredSignatures: Int
        let readonlySigned: Int
        let readonlyUnsigned: Int
    }
}

// MARK: - Instruction

extension CollectiblesPreparedTransaction {
    struct Instruction {
        let programIndex: Int
        let accountIndices: [Int]
        let data: Data
    }
}

// MARK: - Private logic

private extension CollectiblesPreparedTransaction {
    static func readInstruction(from reader: inout BinaryReader) throws -> Instruction {
        let programIndex = Int(try reader.read())
        let accountCount = try readLength(from: &reader)
        let accountIndices = try reader.read(count: accountCount).map(Int.init)
        let dataLength = try readLength(from: &reader)
        let data = Data(try reader.read(count: dataLength))

        return Instruction(programIndex: programIndex, accountIndices: accountIndices, data: data)
    }

    static func readLength(from reader: inout BinaryReader) throws -> Int {
        let length = try reader.decodeLength()

        guard (0 ... Int(UInt16.max)).contains(length) else {
            throw ParsingError.invalidLength
        }

        return length
    }

    func validate() throws {
        guard signatures.count == header.requiredSignatures else {
            throw ParsingError.signatureSlotsMismatch
        }

        let unsignedCount = accountKeys.count - header.requiredSignatures

        guard unsignedCount >= 0,
              header.readonlySigned <= header.requiredSignatures,
              header.readonlyUnsigned <= unsignedCount else {
            throw ParsingError.malformedHeader
        }

        let referencedIndices = instructions.flatMap { [$0.programIndex] + $0.accountIndices }

        guard referencedIndices.allSatisfy({ accountKeys.indices.contains($0) }) else {
            throw ParsingError.indexOutsideAccountKeys
        }
    }
}

// MARK: - Error

extension CollectiblesPreparedTransaction {
    enum ParsingError: Error {
        case invalidLength
        case unsupportedMessageVersion
        case addressTableLookups
        case trailingBytes
        case missingSignatures
        case signatureSlotsMismatch
        case malformedHeader
        case indexOutsideAccountKeys
    }
}

// MARK: - Constants

private extension CollectiblesPreparedTransaction {
    enum Constants {
        static let signatureLength = 64
        static let publicKeyLength = 32
        static let blockhashLength = 32
        static let versionedMessageMask: UInt8 = 0x80
        static let supportedMessageVersion: UInt8 = 0
    }
}
