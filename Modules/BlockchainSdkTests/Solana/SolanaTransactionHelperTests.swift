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
        let unsigned = "010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000709457e1b8faf3cc24988c7416acef1066088a46411ad5cedc30a70943e008f5f15f5bb7e96e98ac7113d2dd578044070ede30bb61ed0ef4e0df49db168657880ba0000000000000000000000000000000000000000000000000000000000000000f2afc06308af48267bcade2d22a6332d9607252d1d88b9d4b9d91f7bce6ec4c506a1d8179137542a983437bdfe2a7ab2557f535c8a78722b68a49dc00000000006a1d817a502050b680791e6ce6db88e1e5b7150f61fc6790a4eb4d10000000006a7d51718c774c928566398691d5eb68b5eb8a39b4b6d5c73555b210000000006a7d517192c5c51218cc94c3d4af17f58daee089ba1fd44e3dbd98a0000000006a7d517193584d0feed9bb3431d13206be544281b57b8566cc5375ff400000092ba528ef980924d516fa35a49d228a8d451d89a4a149a8988ad5e15325c09f603020200017a03000000457e1b8faf3cc24988c7416acef1066088a46411ad5cedc30a70943e008f5f151e00000000000000643430376563313538636638333730363034303235383962393865316464c0c62d0000000000c80000000000000006a1d8179137542a983437bdfe2a7ab2557f535c8a78722b68a49dc000000000040201077400000000457e1b8faf3cc24988c7416acef1066088a46411ad5cedc30a70943e008f5f15457e1b8faf3cc24988c7416acef1066088a46411ad5cedc30a70943e008f5f1500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004060103060805000402000000"

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
