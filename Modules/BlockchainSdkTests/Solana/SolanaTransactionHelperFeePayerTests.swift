//
//  SolanaTransactionHelperFeePayerTests.swift
//  BlockchainSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import BlockchainSdk

@Suite("Solana fee payer injection")
struct SolanaTransactionHelperFeePayerTests {
    private let sut = SolanaTransactionHelper()

    @Test("A legacy message gets the fee payer at index 0 and every instruction index shifted by one")
    func legacyMessageIsRewritten() throws {
        let transaction = makeTransaction(accountKeys: [Self.wallet, Self.destination, Self.program])

        let result = try sut.injectFeePayer(Self.feePayer, walletPublicKey: Self.wallet, into: transaction)

        let expected = makeTransaction(
            signatureSlotCount: 2,
            header: [2, 0, 1],
            accountKeys: [Self.feePayer, Self.wallet, Self.destination, Self.program],
            programIdIndex: 3,
            accountIndices: [1, 2]
        )
        #expect(result == expected)
    }

    @Test("A v0 message keeps its lookup tables and shifts indices that point into them")
    func versionedMessageKeepsLookupTables() throws {
        let lookupTables = Data([1]) + Self.lookupTable + Data([1, 0, 1, 1])
        let transaction = makeTransaction(
            isVersioned: true,
            accountKeys: [Self.wallet, Self.destination, Self.program],
            accountIndices: [0, 3],
            lookupTables: lookupTables
        )

        let result = try sut.injectFeePayer(Self.feePayer, walletPublicKey: Self.wallet, into: transaction)

        let expected = makeTransaction(
            signatureSlotCount: 2,
            isVersioned: true,
            header: [2, 0, 1],
            accountKeys: [Self.feePayer, Self.wallet, Self.destination, Self.program],
            programIdIndex: 3,
            accountIndices: [1, 4],
            lookupTables: lookupTables
        )
        #expect(result == expected)
    }

    @Test("A transaction that already carries a signature is refused")
    func signedTransactionIsRefused() {
        let transaction = makeTransaction(signatureFill: 1, accountKeys: [Self.wallet, Self.destination, Self.program])

        #expect(throws: SolanaGaslessError.transactionAlreadySigned) {
            try sut.injectFeePayer(Self.feePayer, walletPublicKey: Self.wallet, into: transaction)
        }
    }

    @Test("A transaction whose first account is not the wallet is refused")
    func foreignFeePayerIsRefused() {
        let transaction = makeTransaction(accountKeys: [Self.destination, Self.wallet, Self.program])

        #expect(throws: SolanaGaslessError.walletIsNotFeePayer) {
            try sut.injectFeePayer(Self.feePayer, walletPublicKey: Self.wallet, into: transaction)
        }
    }

    @Test("A transaction that already lists the sponsor account is refused")
    func presentFeePayerIsRefused() {
        let transaction = makeTransaction(accountKeys: [Self.wallet, Self.feePayer, Self.program])

        #expect(throws: SolanaGaslessError.feePayerAlreadyPresent) {
            try sut.injectFeePayer(Self.feePayer, walletPublicKey: Self.wallet, into: transaction)
        }
    }

    @Test("A fee payer key of the wrong length is refused")
    func invalidFeePayerIsRefused() {
        let transaction = makeTransaction(accountKeys: [Self.wallet, Self.destination, Self.program])

        #expect(throws: SolanaGaslessError.invalidFeePayer) {
            try sut.injectFeePayer(Data(repeating: 9, count: 31), walletPublicKey: Self.wallet, into: transaction)
        }
    }

    @Test("An instruction index that cannot be shifted is refused")
    func indexOverflowIsRefused() {
        let transaction = makeTransaction(accountKeys: [Self.wallet, Self.destination, Self.program], accountIndices: [0, 255])

        #expect(throws: SolanaGaslessError.accountIndexOverflow) {
            try sut.injectFeePayer(Self.feePayer, walletPublicKey: Self.wallet, into: transaction)
        }
    }
}

// MARK: - Helpers

private extension SolanaTransactionHelperFeePayerTests {
    static let feePayer = Data(repeating: 0xF1, count: 32)
    static let wallet = Data(repeating: 0xA1, count: 32)
    static let destination = Data(repeating: 0xB2, count: 32)
    static let program = Data(repeating: 0xC3, count: 32)
    static let lookupTable = Data(repeating: 0xD4, count: 32)
    static let blockhash = Data(repeating: 0x07, count: 32)
    static let instructionData = Data([1, 2, 3])

    func makeTransaction(
        signatureSlotCount: UInt8 = 1,
        signatureFill: UInt8 = 0,
        isVersioned: Bool = false,
        header: [UInt8] = [1, 0, 1],
        accountKeys: [Data],
        programIdIndex: UInt8 = 2,
        accountIndices: [UInt8] = [0, 1],
        lookupTables: Data = Data()
    ) -> Data {
        var data = Data([signatureSlotCount])
        data.append(Data(repeating: signatureFill, count: Int(signatureSlotCount) * 64))

        if isVersioned {
            data.append(0x80)
        }

        data.append(contentsOf: header)
        data.append(UInt8(accountKeys.count))
        accountKeys.forEach { data.append($0) }
        data.append(Self.blockhash)

        data.append(1)
        data.append(programIdIndex)
        data.append(UInt8(accountIndices.count))
        data.append(contentsOf: accountIndices)
        data.append(UInt8(Self.instructionData.count))
        data.append(Self.instructionData)

        data.append(lookupTables)
        return data
    }
}
