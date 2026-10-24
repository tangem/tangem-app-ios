//
//  SolanaTransactionHelperTests.swift
//  BlockchainSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import Testing
@testable import BlockchainSdk

struct SolanaTransactionHelperTests {
    private let sizeTester: TransactionSizeTesterUtility
    private let helper: SolanaTransactionHelper

    init() {
        sizeTester = .init()
        helper = .init()
    }

    @Test
    func transaction() throws {
        let unsigned = SolanaTransactionHelperTests.realUnsignedTransaction

        let estimateDataToSign = "01000709457e1b8faf3cc24988c7416acef1066088a46411ad5cedc30a70943e008f5f15f5bb7e96e98ac7113d2dd578044070ede30bb61ed0ef4e0df49db168657880ba0000000000000000000000000000000000000000000000000000000000000000f2afc06308af48267bcade2d22a6332d9607252d1d88b9d4b9d91f7bce6ec4c506a1d8179137542a983437bdfe2a7ab2557f535c8a78722b68a49dc00000000006a1d817a502050b680791e6ce6db88e1e5b7150f61fc6790a4eb4d10000000006a7d51718c774c928566398691d5eb68b5eb8a39b4b6d5c73555b210000000006a7d517192c5c51218cc94c3d4af17f58daee089ba1fd44e3dbd98a0000000006a7d517193584d0feed9bb3431d13206be544281b57b8566cc5375ff400000092ba528ef980924d516fa35a49d228a8d451d89a4a149a8988ad5e15325c09f603020200017a03000000457e1b8faf3cc24988c7416acef1066088a46411ad5cedc30a70943e008f5f151e00000000000000643430376563313538636638333730363034303235383962393865316464c0c62d0000000000c80000000000000006a1d8179137542a983437bdfe2a7ab2557f535c8a78722b68a49dc000000000040201077400000000457e1b8faf3cc24988c7416acef1066088a46411ad5cedc30a70943e008f5f15457e1b8faf3cc24988c7416acef1066088a46411ad5cedc30a70943e008f5f1500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004060103060805000402000000"

        let estimateDataToSend = "010202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020201000709457e1b8faf3cc24988c7416acef1066088a46411ad5cedc30a70943e008f5f15f5bb7e96e98ac7113d2dd578044070ede30bb61ed0ef4e0df49db168657880ba0000000000000000000000000000000000000000000000000000000000000000f2afc06308af48267bcade2d22a6332d9607252d1d88b9d4b9d91f7bce6ec4c506a1d8179137542a983437bdfe2a7ab2557f535c8a78722b68a49dc00000000006a1d817a502050b680791e6ce6db88e1e5b7150f61fc6790a4eb4d10000000006a7d51718c774c928566398691d5eb68b5eb8a39b4b6d5c73555b210000000006a7d517192c5c51218cc94c3d4af17f58daee089ba1fd44e3dbd98a0000000006a7d517193584d0feed9bb3431d13206be544281b57b8566cc5375ff400000092ba528ef980924d516fa35a49d228a8d451d89a4a149a8988ad5e15325c09f603020200017a03000000457e1b8faf3cc24988c7416acef1066088a46411ad5cedc30a70943e008f5f151e00000000000000643430376563313538636638333730363034303235383962393865316464c0c62d0000000000c80000000000000006a1d8179137542a983437bdfe2a7ab2557f535c8a78722b68a49dc000000000040201077400000000457e1b8faf3cc24988c7416acef1066088a46411ad5cedc30a70943e008f5f15457e1b8faf3cc24988c7416acef1066088a46411ad5cedc30a70943e008f5f1500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004060103060805000402000000"

        let dummySignature = Data(repeating: 2, count: 64)
        let unsignedData = Data(hexString: unsigned)
        let dataToSign = (try helper.removeSignaturesPlaceholders(from: unsignedData)).transaction
        #expect(dataToSign.hex() == estimateDataToSign)

        #expect(sizeTester.isValidForCos4_52AndAbove(dataToSign))
        #expect(!sizeTester.isValidForIPhone7(dataToSign))
        #expect(!sizeTester.isValidForCosBelow4_52(dataToSign))

        let dataToSend = try helper.addSignature(dummySignature, transaction: unsignedData)
        #expect(dataToSend == Data(hexString: estimateDataToSend).base64EncodedString())
    }

    // MARK: - putSignature

    @Test
    func putSignaturePlacesSignatureInWalletSlotPreservingOtherSlots() throws {
        let coSignerSignature = Data(repeating: 0x11, count: MultiSigner.signatureLength)
        let ourSignature = Data(repeating: 0x77, count: MultiSigner.signatureLength)
        let transaction = MultiSigner.transaction(
            firstSlot: coSignerSignature,
            secondSlot: Data(repeating: 0x00, count: MultiSigner.signatureLength)
        )

        let signed = try helper.putSignature(ourSignature, publicKey: MultiSigner.ourKey, transaction: transaction)

        // Our signature spliced into slot 1; the co-signer's slot, the count byte and the message stay byte-identical.
        let expected = MultiSigner.transaction(firstSlot: coSignerSignature, secondSlot: ourSignature)
        #expect(signed == expected)
    }

    @Test
    func putSignatureSignsFeePayerSlotWhenWalletIsSignerIndexZero() throws {
        let feePayerSignature = Data(repeating: 0x55, count: MultiSigner.signatureLength)
        let untouchedSlot = Data(repeating: 0x00, count: MultiSigner.signatureLength)
        let transaction = MultiSigner.transaction(firstSlot: untouchedSlot, secondSlot: untouchedSlot)

        let signed = try helper.putSignature(feePayerSignature, publicKey: MultiSigner.feePayerKey, transaction: transaction)

        let expected = MultiSigner.transaction(firstSlot: feePayerSignature, secondSlot: untouchedSlot)
        #expect(signed == expected)
    }

    @Test
    func putSignatureFailsWhenPublicKeyIsNotRequiredSigner() throws {
        let strangerKey = Data(repeating: 0xEE, count: MultiSigner.publicKeyLength)
        let transaction = MultiSigner.transaction(
            firstSlot: Data(repeating: 0x00, count: MultiSigner.signatureLength),
            secondSlot: Data(repeating: 0x00, count: MultiSigner.signatureLength)
        )

        do {
            _ = try helper.putSignature(
                Data(repeating: 0x77, count: MultiSigner.signatureLength),
                publicKey: strangerKey,
                transaction: transaction
            )
            Issue.record("Expected SolanaBSDKError.signerPublicKeyNotFound")
        } catch SolanaBSDKError.signerPublicKeyNotFound {
            // Expected
        }
    }

    @Test
    func putSignatureFailsWhenAccountIsPresentButNotSigner() throws {
        let transaction = MultiSigner.transaction(
            firstSlot: Data(repeating: 0x00, count: MultiSigner.signatureLength),
            secondSlot: Data(repeating: 0x00, count: MultiSigner.signatureLength)
        )

        do {
            _ = try helper.putSignature(
                Data(repeating: 0x77, count: MultiSigner.signatureLength),
                publicKey: MultiSigner.programKey,
                transaction: transaction
            )
            Issue.record("Expected SolanaBSDKError.signerPublicKeyNotFound")
        } catch SolanaBSDKError.signerPublicKeyNotFound {
            // Expected
        }
    }

    @Test
    func putSignatureFailsForWrongSignatureLength() throws {
        let transaction = MultiSigner.transaction(
            firstSlot: Data(repeating: 0x00, count: MultiSigner.signatureLength),
            secondSlot: Data(repeating: 0x00, count: MultiSigner.signatureLength)
        )

        do {
            _ = try helper.putSignature(
                Data(repeating: 0x77, count: MultiSigner.signatureLength - 1),
                publicKey: MultiSigner.ourKey,
                transaction: transaction
            )
            Issue.record("Expected SolanaBSDKError.invalidSignatureLength")
        } catch SolanaBSDKError.invalidSignatureLength {
            // Expected
        }
    }

    @Test
    func putSignatureDoesNotResolveSlotBeyondRealSignatureBlock() throws {
        // The header claims two required signers, but only one signature slot exists. ourKey is signer index 1
        // per the header — it must not resolve to a slot that lies inside the message.
        do {
            _ = try helper.putSignature(
                Data(repeating: 0x77, count: MultiSigner.signatureLength),
                publicKey: MultiSigner.ourKey,
                transaction: MultiSigner.oneSlotButTwoRequiredSigners
            )
            Issue.record("Expected SolanaBSDKError.signerPublicKeyNotFound")
        } catch SolanaBSDKError.signerPublicKeyNotFound {
            // Expected
        }
    }

    // MARK: - isTransactionMessage

    @Test
    func isSoleRequiredSignerAcceptsOnlyTheSingleFeePayer() throws {
        #expect(try helper.isSoleRequiredSigner(MultiSigner.feePayerKey, transaction: SoleSigner.transaction))
        #expect(try helper.isSoleRequiredSigner(MultiSigner.ourKey, transaction: SoleSigner.transaction) == false)
    }

    @Test
    func isSoleRequiredSignerRejectsHeaderDeclaringMoreSignersThanAccounts() throws {
        #expect(try helper.isSoleRequiredSigner(MultiSigner.feePayerKey, transaction: SoleSigner.twoSignersDeclaredOneAccount) == false)
    }

    @Test
    func isSoleRequiredSignerRejectsEverySignerOfMultiSignerTransaction() throws {
        let emptySlot = Data(repeating: 0x00, count: MultiSigner.signatureLength)
        let transaction = MultiSigner.transaction(firstSlot: emptySlot, secondSlot: emptySlot)

        #expect(try helper.isSoleRequiredSigner(MultiSigner.feePayerKey, transaction: transaction) == false)
        #expect(try helper.isSoleRequiredSigner(MultiSigner.ourKey, transaction: transaction) == false)
    }

    @Test
    func isTransactionMessageDetectsRealLegacyTransactionMessage() throws {
        let transaction = Data(hexString: SolanaTransactionHelperTests.realUnsignedTransaction)
        let message = try helper.removeSignaturesPlaceholders(from: transaction).transaction

        #expect(helper.isTransactionMessage(message))
    }

    @Test
    func isTransactionMessageDetectsLegacyTransferMessage() {
        #expect(helper.isTransactionMessage(TransactionMessage.legacyTransfer()))
        #expect(helper.isTransactionMessage(MultiSigner.message))
    }

    @Test
    func isTransactionMessageDetectsVersionedMessageWithoutLookupTables() {
        #expect(helper.isTransactionMessage(TransactionMessage.versioned(accountIndexes: [0, 1], lookups: [])))
    }

    @Test
    func isTransactionMessageDetectsMessageWithoutInstructions() {
        var message = Data([0x01, 0x00, 0x00, 0x01])
        message.append(TransactionMessage.victimKey)
        message.append(MultiSigner.blockhash)
        message.append(0x00)

        #expect(helper.isTransactionMessage(message))
    }

    @Test
    func isTransactionMessageDetectsMessageWithAllSignersReadonly() {
        #expect(helper.isTransactionMessage(TransactionMessage.legacyTransfer(header: [0x01, 0x01, 0x01])))
    }

    @Test
    func isTransactionMessageDetectsNonCanonicalCompactLength() {
        var message = TransactionMessage.legacyTransfer()
        message.replaceSubrange(3 ..< 4, with: [0x83, 0x00])

        #expect(helper.isTransactionMessage(message))
    }

    @Test
    func isTransactionMessageDetectsVersionedMessageWithLookupTables() {
        let lookups = [
            TransactionMessage.Lookup(writableIndexes: [0], readonlyIndexes: [1, 2]),
            TransactionMessage.Lookup(writableIndexes: [], readonlyIndexes: [0]),
        ]

        #expect(helper.isTransactionMessage(TransactionMessage.versioned(lookups: lookups)))
    }

    @Test
    func isTransactionMessageDetectsVersionedMessageWithAccountsFromLookupTables() {
        let message = TransactionMessage.versioned(
            accountIndexes: [0, 3, 5],
            lookups: [
                TransactionMessage.Lookup(writableIndexes: [0], readonlyIndexes: [1]),
                TransactionMessage.Lookup(writableIndexes: [], readonlyIndexes: [0, 1]),
            ]
        )

        #expect(helper.isTransactionMessage(message))
    }

    @Test
    func isTransactionMessageRejectsTrailingBytes() {
        let lookups = [TransactionMessage.Lookup(writableIndexes: [0], readonlyIndexes: [1])]

        #expect(!helper.isTransactionMessage(TransactionMessage.legacyTransfer() + [0x00]))
        #expect(!helper.isTransactionMessage(TransactionMessage.versioned(lookups: lookups) + [0x00]))
    }

    @Test
    func isTransactionMessageRejectsTruncatedMessages() {
        let legacy = TransactionMessage.legacyTransfer()
        let versioned = TransactionMessage.versioned(
            lookups: [TransactionMessage.Lookup(writableIndexes: [0], readonlyIndexes: [1])]
        )

        #expect(!helper.isTransactionMessage(legacy.dropLast()))
        #expect(!helper.isTransactionMessage(versioned.dropLast()))
    }

    @Test
    func isTransactionMessageRejectsUnsupportedMessageVersion() {
        var message = TransactionMessage.versioned(lookups: [])
        message[0] = 0x81

        #expect(!helper.isTransactionMessage(message))
    }

    @Test
    func isTransactionMessageRejectsInconsistentHeaders() {
        #expect(!helper.isTransactionMessage(TransactionMessage.legacyTransfer(header: [0x00, 0x00, 0x01])))
        #expect(!helper.isTransactionMessage(TransactionMessage.legacyTransfer(header: [0x04, 0x00, 0x00])))
        #expect(!helper.isTransactionMessage(TransactionMessage.legacyTransfer(header: [0x01, 0x02, 0x00])))
        #expect(!helper.isTransactionMessage(TransactionMessage.legacyTransfer(header: [0x01, 0x00, 0x03])))
    }

    @Test
    func isTransactionMessageRejectsLegacyIndexesOutsideStaticAccounts() {
        #expect(!helper.isTransactionMessage(TransactionMessage.legacyTransfer(programIdIndex: 3)))
        #expect(!helper.isTransactionMessage(TransactionMessage.legacyTransfer(accountIndexes: [0, 3])))
    }

    @Test
    func isTransactionMessageRejectsTransactionWithSignaturePlaceholders() {
        var transaction = Data([0x01])
        transaction.append(Data(repeating: 0x00, count: MultiSigner.signatureLength))
        transaction.append(TransactionMessage.legacyTransfer())

        #expect(!helper.isTransactionMessage(transaction))
    }

    @Test(arguments: [
        "",
        "example.com wants you to sign in with your Solana account:\nHN7cABqLq46Es1jh92dQQisAq662SmxELLLsHHe4YWrH\n\nNonce: 32891756",
        "\u{41F}\u{440}\u{438}\u{432}\u{435}\u{442}! \u{412}\u{43E}\u{439}\u{434}\u{438}\u{442}\u{435}.",
        "🔐 Sign in to dApp",
    ])
    func isTransactionMessageIgnoresHumanReadableMessages(text: String) {
        #expect(!helper.isTransactionMessage(Data(text.utf8)))
    }

    @Test
    func isTransactionMessageDoesNotCrashOnOversizedCompactLengths() {
        var message = Data([0x01, 0x00, 0x00])
        message.append(Data(repeating: 0xFF, count: 16))
        message.append(0x01)

        #expect(!helper.isTransactionMessage(message))
    }

    @Test
    func putSignatureThrowsInsteadOfCrashingOnTruncatedMessage() throws {
        // One signature slot followed by a one-byte message: the signer-key read runs out of bytes. It must throw,
        // not trap the process.
        var truncated = Data()
        truncated.append(0x01) // signature count = 1
        truncated.append(Data(repeating: 0x00, count: MultiSigner.signatureLength))
        truncated.append(0x02) // message = single header byte, nothing after it

        #expect(throws: (any Error).self) {
            _ = try helper.putSignature(
                Data(repeating: 0x77, count: MultiSigner.signatureLength),
                publicKey: MultiSigner.ourKey,
                transaction: truncated
            )
        }
    }

    @Test
    func putSignatureThrowsWhenSignatureBlockExceedsData() throws {
        // Declares 3 signature slots but only one slot's worth of bytes follows the count. Reading the block must
        // fail with an error rather than let the slot index run into the message or past the buffer.
        var overDeclared = Data()
        overDeclared.append(0x03)
        overDeclared.append(Data(repeating: 0x00, count: MultiSigner.signatureLength))

        #expect(throws: (any Error).self) {
            _ = try helper.putSignature(
                Data(repeating: 0x77, count: MultiSigner.signatureLength),
                publicKey: MultiSigner.ourKey,
                transaction: overDeclared
            )
        }
    }

    @Test
    func replaceRecentBlockhashSwapsOnlyTheBlockhash() throws {
        let original = Data(hexString: SolanaTransactionHelperTests.realUnsignedTransaction)
        let window = BlockhashFixtures.realBlockhashOffset ..< BlockhashFixtures.realBlockhashOffset + MultiSigner.publicKeyLength

        #expect(original[window].hex() == "92ba528ef980924d516fa35a49d228a8d451d89a4a149a8988ad5e15325c09f6")

        let patched = try helper.replaceRecentBlockhash(BlockhashFixtures.freshBlockhash, in: original)

        #expect(patched.count == original.count)
        #expect(Data(patched[window]) == BlockhashFixtures.freshBlockhash)
        #expect(patched.prefix(window.lowerBound).elementsEqual(original.prefix(window.lowerBound)))
        #expect(patched.dropFirst(window.upperBound).elementsEqual(original.dropFirst(window.upperBound)))
    }

    @Test
    func replaceRecentBlockhashKeepsTransactionWellFormed() throws {
        let original = Data(hexString: SolanaTransactionHelperTests.realUnsignedTransaction)
        let patched = try helper.replaceRecentBlockhash(BlockhashFixtures.freshBlockhash, in: original)

        let message = try helper.removeSignaturesPlaceholders(from: patched)

        #expect(message.signatureCount == 1)
        #expect(helper.isTransactionMessage(message.transaction))

        let signed = try helper.addSignature(Data(repeating: 0x02, count: MultiSigner.signatureLength), transaction: patched)
        #expect(!signed.isEmpty)
    }

    @Test
    func replaceRecentBlockhashHandlesVersionedMessage() throws {
        let original = BlockhashFixtures.withSignaturePlaceholder(TransactionMessage.versioned(lookups: []))
        let patched = try helper.replaceRecentBlockhash(BlockhashFixtures.freshBlockhash, in: original)

        #expect(patched.count == original.count)
        #expect(patched.range(of: BlockhashFixtures.freshBlockhash) != nil)
        #expect(patched.range(of: MultiSigner.blockhash) == nil)
        try helper.assertDiffersOnlyInRecentBlockhash(original: original, patched: patched)
    }

    @Test
    func replaceRecentBlockhashRejectsDurableNonce() throws {
        let transaction = BlockhashFixtures.withSignaturePlaceholder(BlockhashFixtures.durableNonceMessage)

        #expect {
            _ = try helper.replaceRecentBlockhash(BlockhashFixtures.freshBlockhash, in: transaction)
        } throws: { error in
            guard case SolanaBSDKError.durableNonceTransaction = error else { return false }
            return true
        }
    }

    @Test
    func replaceRecentBlockhashRejectsProgramIdOutsideStaticKeys() throws {
        let transaction = BlockhashFixtures.withSignaturePlaceholder(
            TransactionMessage.legacyTransfer(programIdIndex: 9)
        )

        #expect {
            _ = try helper.replaceRecentBlockhash(BlockhashFixtures.freshBlockhash, in: transaction)
        } throws: { error in
            guard case SolanaBSDKError.programIdOutsideStaticKeys = error else { return false }
            return true
        }
    }

    @Test(arguments: [31, 33, 0])
    func replaceRecentBlockhashRejectsWrongLength(length: Int) throws {
        let original = Data(hexString: SolanaTransactionHelperTests.realUnsignedTransaction)

        #expect {
            _ = try helper.replaceRecentBlockhash(Data(repeating: 0x5A, count: length), in: original)
        } throws: { error in
            guard case SolanaBSDKError.invalidBlockhashLength = error else { return false }
            return true
        }
    }

    @Test
    func assertDiffersOnlyInRecentBlockhashAcceptsPatchedTransaction() throws {
        let original = Data(hexString: SolanaTransactionHelperTests.realUnsignedTransaction)
        let patched = try helper.replaceRecentBlockhash(BlockhashFixtures.freshBlockhash, in: original)

        try helper.assertDiffersOnlyInRecentBlockhash(original: original, patched: patched)
    }

    @Test(arguments: [0, 100, 356, 389, 650])
    func assertDiffersOnlyInRecentBlockhashRejectsMutationOutsideTheWindow(index: Int) throws {
        let original = Data(hexString: SolanaTransactionHelperTests.realUnsignedTransaction)
        var patched = try helper.replaceRecentBlockhash(BlockhashFixtures.freshBlockhash, in: original)
        patched[patched.startIndex + index] ^= 0xFF

        #expect {
            try helper.assertDiffersOnlyInRecentBlockhash(original: original, patched: patched)
        } throws: { error in
            guard case SolanaBSDKError.unexpectedTransactionMutation = error else { return false }
            return true
        }
    }

    @Test
    func assertDiffersOnlyInRecentBlockhashRejectsLengthChange() throws {
        let original = Data(hexString: SolanaTransactionHelperTests.realUnsignedTransaction)

        #expect {
            try helper.assertDiffersOnlyInRecentBlockhash(original: original, patched: original.dropLast())
        } throws: { error in
            guard case SolanaBSDKError.unexpectedTransactionMutation = error else { return false }
            return true
        }
    }
}

private extension SolanaTransactionHelperTests {
    static let realUnsignedTransaction = "010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000709457e1b8faf3cc24988c7416acef1066088a46411ad5cedc30a70943e008f5f15f5bb7e96e98ac7113d2dd578044070ede30bb61ed0ef4e0df49db168657880ba0000000000000000000000000000000000000000000000000000000000000000f2afc06308af48267bcade2d22a6332d9607252d1d88b9d4b9d91f7bce6ec4c506a1d8179137542a983437bdfe2a7ab2557f535c8a78722b68a49dc00000000006a1d817a502050b680791e6ce6db88e1e5b7150f61fc6790a4eb4d10000000006a7d51718c774c928566398691d5eb68b5eb8a39b4b6d5c73555b210000000006a7d517192c5c51218cc94c3d4af17f58daee089ba1fd44e3dbd98a0000000006a7d517193584d0feed9bb3431d13206be544281b57b8566cc5375ff400000092ba528ef980924d516fa35a49d228a8d451d89a4a149a8988ad5e15325c09f603020200017a03000000457e1b8faf3cc24988c7416acef1066088a46411ad5cedc30a70943e008f5f151e00000000000000643430376563313538636638333730363034303235383962393865316464c0c62d0000000000c80000000000000006a1d8179137542a983437bdfe2a7ab2557f535c8a78722b68a49dc000000000040201077400000000457e1b8faf3cc24988c7416acef1066088a46411ad5cedc30a70943e008f5f15457e1b8faf3cc24988c7416acef1066088a46411ad5cedc30a70943e008f5f1500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004060103060805000402000000"
}

private enum BlockhashFixtures {
    static let realBlockhashOffset = 357
    static let freshBlockhash = Data(repeating: 0x5A, count: MultiSigner.publicKeyLength)

    static let durableNonceMessage: Data = {
        var data = Data([0x01, 0x00, 0x01])
        data.append(0x03)
        data.append(TransactionMessage.victimKey)
        data.append(TransactionMessage.attackerKey)
        data.append(TransactionMessage.systemProgramKey)
        data.append(MultiSigner.blockhash)
        data.append(0x01)
        data.append(0x02)
        data.append(0x03)
        data.append(contentsOf: [0x00, 0x01, 0x02] as [UInt8])
        data.append(0x04)
        data.append(contentsOf: [0x04, 0x00, 0x00, 0x00] as [UInt8])
        return data
    }()

    static func withSignaturePlaceholder(_ message: Data) -> Data {
        var data = Data([0x01])
        data.append(Data(repeating: 0x00, count: MultiSigner.signatureLength))
        data.append(message)
        return data
    }
}

private enum TransactionMessage {
    struct Lookup {
        let writableIndexes: [UInt8]
        let readonlyIndexes: [UInt8]
    }

    static let victimKey = Data(repeating: 0xA0, count: MultiSigner.publicKeyLength)
    static let attackerKey = Data(repeating: 0xB1, count: MultiSigner.publicKeyLength)
    static let systemProgramKey = Data(repeating: 0x00, count: MultiSigner.publicKeyLength)
    static let lookupTableKey = Data(repeating: 0xE4, count: MultiSigner.publicKeyLength)
    static let transferInstructionData = Data([0x02, 0x00, 0x00, 0x00, 0x00, 0x65, 0xCD, 0x1D, 0x00, 0x00, 0x00, 0x00])

    static func legacyTransfer(
        header: [UInt8] = [0x01, 0x00, 0x01],
        programIdIndex: UInt8 = 2,
        accountIndexes: [UInt8] = [0, 1]
    ) -> Data {
        var data = Data(header)
        data.append(0x03)
        data.append(victimKey)
        data.append(attackerKey)
        data.append(systemProgramKey)
        data.append(MultiSigner.blockhash)
        data.append(0x01)
        data.append(programIdIndex)
        data.append(UInt8(accountIndexes.count))
        data.append(contentsOf: accountIndexes)
        data.append(UInt8(transferInstructionData.count))
        data.append(transferInstructionData)
        return data
    }

    static func versioned(accountIndexes: [UInt8] = [0, 2], lookups: [Lookup]) -> Data {
        var data = Data([0x80, 0x01, 0x00, 0x01])
        data.append(0x02)
        data.append(victimKey)
        data.append(systemProgramKey)
        data.append(MultiSigner.blockhash)
        data.append(0x01)
        data.append(0x01)
        data.append(UInt8(accountIndexes.count))
        data.append(contentsOf: accountIndexes)
        data.append(UInt8(transferInstructionData.count))
        data.append(transferInstructionData)
        data.append(UInt8(lookups.count))
        for lookup in lookups {
            data.append(lookupTableKey)
            data.append(UInt8(lookup.writableIndexes.count))
            data.append(contentsOf: lookup.writableIndexes)
            data.append(UInt8(lookup.readonlyIndexes.count))
            data.append(contentsOf: lookup.readonlyIndexes)
        }
        return data
    }
}

private enum MultiSigner {
    static let signatureLength = 64
    static let publicKeyLength = 32

    static let feePayerKey = Data(repeating: 0xA0, count: publicKeyLength)
    static let ourKey = Data(repeating: 0xB1, count: publicKeyLength)
    static let programKey = Data(repeating: 0xC2, count: publicKeyLength)
    static let blockhash = Data(repeating: 0xD3, count: publicKeyLength)

    /// A well-formed legacy message with 2 required signers and 3 static accounts (fee-payer, our wallet, program),
    /// a blockhash and a single instruction referencing accounts 0 and 1.
    static let message: Data = {
        var data = Data()
        data.append(contentsOf: [0x02, 0x00, 0x01]) // header: 2 required signatures, 0 readonly signed, 1 readonly unsigned
        data.append(0x03) // account count
        data.append(feePayerKey)
        data.append(ourKey)
        data.append(programKey)
        data.append(blockhash)
        data.append(0x01) // instruction count
        data.append(0x02) // program id index -> program key
        data.append(contentsOf: [0x02, 0x00, 0x01]) // 2 account indices -> [0, 1]
        data.append(0x00) // data length
        return data
    }()

    static func transaction(firstSlot: Data, secondSlot: Data) -> Data {
        var data = Data()
        data.append(0x02) // signature count
        data.append(firstSlot)
        data.append(secondSlot)
        data.append(message)
        return data
    }

    /// A malformed transaction: the transaction-level signature count is 1 (a single slot), while the message
    /// header claims 2 required signers (fee-payer and our wallet).
    static let oneSlotButTwoRequiredSigners: Data = {
        var message = Data()
        message.append(contentsOf: [0x02, 0x00, 0x00]) // header claims 2 required signers
        message.append(0x02) // account count = 2
        message.append(feePayerKey)
        message.append(ourKey)
        message.append(blockhash)
        message.append(0x00) // instruction count = 0

        var data = Data()
        data.append(0x01) // signature count = 1 — only one real slot
        data.append(Data(repeating: 0x00, count: signatureLength))
        data.append(message)
        return data
    }()
}

private enum SoleSigner {
    static let transaction: Data = {
        var data = Data()
        data.append(0x01)
        data.append(Data(repeating: 0x00, count: MultiSigner.signatureLength))
        data.append(contentsOf: [0x01, 0x00, 0x01])
        data.append(0x03)
        data.append(MultiSigner.feePayerKey)
        data.append(MultiSigner.ourKey)
        data.append(MultiSigner.programKey)
        data.append(MultiSigner.blockhash)
        data.append(0x01)
        data.append(0x02)
        data.append(contentsOf: [0x02, 0x00, 0x01])
        data.append(0x00)
        return data
    }()

    static let twoSignersDeclaredOneAccount: Data = {
        var data = Data()
        data.append(0x01)
        data.append(Data(repeating: 0x00, count: MultiSigner.signatureLength))
        data.append(contentsOf: [0x02, 0x00, 0x00])
        data.append(0x01)
        data.append(MultiSigner.feePayerKey)
        data.append(MultiSigner.blockhash)
        data.append(0x00)
        return data
    }()
}
