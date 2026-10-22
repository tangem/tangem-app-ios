//
//  CollectiblesBuybackTransactionVerifierTests.swift
//  TangemCollectiblesTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import SolanaSwift
import Testing
@testable import TangemCollectibles

@Suite("CollectiblesBuybackTransactionVerifier")
struct CollectiblesBuybackTransactionVerifierTests {
    typealias SUT = CollectiblesBuybackTransactionVerifier
    typealias VerificationError = SUT.VerificationError

    @Test("Accepts the buyback transaction the partner built on devnet")
    func acceptsLiveTransaction() throws {
        try makeSUT().verify(try Fixtures.liveTransaction())
    }

    @Test("Accepts a payout above the agreed price")
    func acceptsHigherPayout() throws {
        let terms = Fixtures.terms(minimumPayout: Fixtures.payout - 1)

        try makeSUT(terms: terms).verify(try Fixtures.liveTransaction())
    }

    @Test("Refuses when the owner's key does not sign the transaction")
    func refusesForeignOwner() throws {
        let sut = makeSUT(owner: Fixtures.strangerKey)
        let transaction = try Fixtures.liveTransaction()

        #expect(throws: VerificationError.ownerNotSigner) {
            try sut.verify(transaction)
        }
    }

    @Test("Refuses a transaction that does not keep the agreed terms", arguments: TermsBreach.allCases)
    func refusesTermsBreach(breach: TermsBreach) throws {
        let sut = makeSUT(usdcMint: breach.usdcMint, payoutAccount: breach.payoutAccount, terms: breach.terms)
        let transaction = try Fixtures.liveTransaction()

        #expect(throws: breach.expectedError) {
            try sut.verify(transaction)
        }
    }

    @Test("Refuses anything beyond the sale itself", arguments: Tampering.allCases)
    func refusesTampering(tampering: Tampering) throws {
        let sut = makeSUT()
        let transaction = tampering.apply(to: try Fixtures.liveTransaction())

        #expect(throws: tampering.expectedError) {
            try sut.verify(transaction)
        }
    }
}

// MARK: - Arguments

extension CollectiblesBuybackTransactionVerifierTests {
    enum TermsBreach: CaseIterable {
        case foreignAsset
        case foreignPayoutAccount
        case foreignMint
        case payoutBelowAgreedPrice

        var terms: CollectiblesBuybackTerms {
            switch self {
            case .foreignAsset: Fixtures.terms(nftAddress: Fixtures.strangerAddress)
            case .foreignPayoutAccount, .foreignMint: Fixtures.terms()
            case .payoutBelowAgreedPrice: Fixtures.terms(minimumPayout: Fixtures.payout + 1)
            }
        }

        var usdcMint: Data {
            switch self {
            case .foreignMint: Fixtures.strangerKey
            case .foreignAsset, .foreignPayoutAccount, .payoutBelowAgreedPrice: Fixtures.usdcMint
            }
        }

        var payoutAccount: String {
            switch self {
            case .foreignPayoutAccount: Fixtures.strangerAddress
            case .foreignAsset, .foreignMint, .payoutBelowAgreedPrice: Fixtures.livePayoutAccount
            }
        }

        var expectedError: VerificationError {
            switch self {
            case .foreignAsset: .foreignAsset
            case .foreignPayoutAccount, .foreignMint: .foreignPayout
            case .payoutBelowAgreedPrice: .payoutBelowAgreedPrice
            }
        }
    }

    enum Tampering: CaseIterable {
        case ownerWritable
        case collectorUnsigned
        case extraSolTransfer
        case payoutAuthorizedByOwner
        case payoutToForeignAccount
        case payoutFromPayoutAccount
        case assetTransferByCollector
        case compressedAssetTransfer
        case foreignAccountCreation
        case repeatedPayout
        case repeatedComputeUnitLimit
        case missingAssetTransfer
        case missingPayout
        case memoWithAccounts

        var expectedError: VerificationError {
            switch self {
            case .ownerWritable: .ownerWritable
            case .collectorUnsigned: .cosignerSignatureMissing
            case .extraSolTransfer: .unexpectedInstruction(index: 6)
            case .payoutAuthorizedByOwner, .payoutFromPayoutAccount: .unexpectedInstruction(index: Fixtures.payoutIndex)
            case .payoutToForeignAccount, .foreignAccountCreation: .foreignPayout
            case .assetTransferByCollector, .compressedAssetTransfer:
                .unexpectedInstruction(index: Fixtures.assetTransferIndex)
            case .repeatedPayout, .repeatedComputeUnitLimit: .repeatedInstruction(index: 6)
            case .missingAssetTransfer, .missingPayout: .missingInstruction
            case .memoWithAccounts: .unexpectedInstruction(index: Fixtures.memoIndex)
            }
        }

        func apply(to transaction: CollectiblesPreparedTransaction) -> CollectiblesPreparedTransaction {
            let instructions = transaction.instructions

            switch self {
            case .ownerWritable:
                let header = CollectiblesPreparedTransaction.Header(
                    requiredSignatures: transaction.header.requiredSignatures,
                    readonlySigned: 0,
                    readonlyUnsigned: transaction.header.readonlyUnsigned
                )
                return transaction.with(header: header)
            case .collectorUnsigned:
                let signatures = [Data(repeating: 0, count: 64)] + transaction.signatures.dropFirst()
                return transaction.with(signatures: signatures)
            case .extraSolTransfer:
                let transfer = CollectiblesPreparedTransaction.Instruction(
                    programIndex: Fixtures.systemProgramKeyIndex,
                    accountIndices: [Fixtures.ownerKeyIndex, Fixtures.collectorKeyIndex],
                    data: Data([2, 0, 0, 0]) + Data(repeating: 0xFF, count: 8)
                )
                return transaction.with(instructions: instructions + [transfer])
            case .payoutAuthorizedByOwner:
                return transaction.replacingAccount(
                    at: 3,
                    ofInstruction: Fixtures.payoutIndex,
                    with: Fixtures.ownerKeyIndex
                )
            case .payoutToForeignAccount:
                return transaction.replacingAccount(
                    at: 2,
                    ofInstruction: Fixtures.payoutIndex,
                    with: Fixtures.collectorKeyIndex
                )
            case .payoutFromPayoutAccount:
                return transaction.replacingAccount(
                    at: 0,
                    ofInstruction: Fixtures.payoutIndex,
                    with: Fixtures.payoutAccountKeyIndex
                )
            case .assetTransferByCollector:
                return transaction.replacingAccount(
                    at: 3,
                    ofInstruction: Fixtures.assetTransferIndex,
                    with: Fixtures.collectorKeyIndex
                )
            case .compressedAssetTransfer:
                return transaction.replacingData(Data([14, 1]), ofInstruction: Fixtures.assetTransferIndex)
            case .foreignAccountCreation:
                return transaction.replacingAccount(
                    at: 1,
                    ofInstruction: Fixtures.accountCreationIndex,
                    with: Fixtures.collectorUsdcKeyIndex
                )
            case .repeatedPayout:
                return transaction.with(instructions: instructions + [instructions[Fixtures.payoutIndex]])
            case .repeatedComputeUnitLimit:
                return transaction.with(instructions: instructions + [instructions[Fixtures.computeUnitLimitIndex]])
            case .missingAssetTransfer:
                return transaction.removingInstruction(at: Fixtures.assetTransferIndex)
            case .missingPayout:
                return transaction.removingInstruction(at: Fixtures.payoutIndex)
            case .memoWithAccounts:
                let memo = instructions[Fixtures.memoIndex]
                let signedMemo = CollectiblesPreparedTransaction.Instruction(
                    programIndex: memo.programIndex,
                    accountIndices: [Fixtures.ownerKeyIndex],
                    data: memo.data
                )
                return transaction.replacingInstruction(at: Fixtures.memoIndex, with: signedMemo)
            }
        }
    }
}

// MARK: - Helpers

private extension CollectiblesBuybackTransactionVerifierTests {
    enum Fixtures {
        static let ownerAddress = "f2AQUg4bys9YrHgL6DvKaZYftB81BsymeRupnsuxMbn"
        static let nftAddress = "GPuvDVEEczHwXiPSxf269xz8Nrnc62ybFk4C1iM6FRR4"
        static let usdcMintAddress = "Gh9ZwEmdLJ8DscKNTkTqPbNwLNNBjuSzaG9Vp2KGtKJr"
        static let strangerAddress = "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v"
        static let livePayoutAccount = "2DqtAcezfgBcdThnb9rx1Fm1MYoNSWjpjHSUVkA4eFHE"
        static let payout: UInt64 = 12_750_000

        static let ownerKey = SolanaSwift.PublicKey(string: ownerAddress)!.data
        static let usdcMint = SolanaSwift.PublicKey(string: usdcMintAddress)!.data
        static let strangerKey = SolanaSwift.PublicKey(string: strangerAddress)!.data

        static let collectorKeyIndex = 0
        static let ownerKeyIndex = 1
        static let payoutAccountKeyIndex = 2
        static let collectorUsdcKeyIndex = 3
        static let systemProgramKeyIndex = 5

        static let computeUnitLimitIndex = 0
        static let assetTransferIndex = 1
        static let accountCreationIndex = 3
        static let payoutIndex = 4
        static let memoIndex = 5

        static let liveBuyback = Data(
            base64Encoded: """
            AlQYLWVifxuPsAw4kVBU/60egRs8r/lVDnpG/WuwV/URqzaHYiQvLx9WUt/i0BamL6IAU7DRiZmdOrcYflFPvQkAAAAAAAAAAAAA
            AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgEJDoakCFBHeIP62Wfd1yRpn2NS
            Ju3WGlYaXwdBjxcDWn9/Cb1igdTOukueBOv4c1erNsqIqkhVXhhkfr5fXw8kbIkSJe2JgFKSNFCWMINiHhZ3TuoDSbbPYbMLFDUx
            djOE/X8tHLsqlhPPfHMQftnlm7Jct1DLzZ9vIrwXjN+kV1ia5L3qa+AoXhua6um6hR+mNKnDalq4TQctR2G/ErAElhMAAAAAAAAA
            AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIyXJY9OJInxuz0QKRSODYMLWhOZ2v8QhASOe9jb6fhZpnp1Fpjwvz4eGn76FE9GJ9oh
            sIsCtacq5krP94RMHvUDBkZv5SEXMv/srbpyw5vnvIzlu8X3EmssQ5s6QAAAAK9UqxC9l6VCoJ73s5iJ3QzTlKTM6d+mzcl+vi0j
            W6dI6Sg5VQll/9TWSsqvRtRd9zGOW09XyQxIfWBiXYKbg3sFEx3Boojpr4HDt2UYv/YIKDiAAK9b/9o7s+EsDGGT5wVKU1qZKSEG
            TSTocWDaOHx8NbXdvJK7geQfqEBBBUSNBt324ddloZPZy+FGzut5rBy0he1fWzeROoz1hX7/AKnJIe4725n4bB0/Bp9qNv3ttl6f
            m/ZiO+7P5HwBEr66rAYIAAUCkNADAAkHBAcAAQsJCQIOAAgACQMgTgAAAAAAAAYGAAIBCgUNAQENBAMKAgAKDLCMwgAAAAAABgwA
            L2NjLWFjMDY3YzRlLTZiYjEtNDA5MS05MTViLTNmNWU5ZjQyZWQ1MDpidXliYWNr
            """,
            options: .ignoreUnknownCharacters
        )!

        static func liveTransaction() throws -> CollectiblesPreparedTransaction {
            try CollectiblesPreparedTransaction(serialized: liveBuyback)
        }

        static func terms(nftAddress: String = nftAddress, minimumPayout: UInt64 = payout) -> CollectiblesBuybackTerms {
            CollectiblesBuybackTerms(nftAddress: nftAddress, minimumPayoutInBaseUnits: minimumPayout)
        }
    }

    func makeSUT(
        owner: Data = Fixtures.ownerKey,
        usdcMint: Data = Fixtures.usdcMint,
        payoutAccount: String = Fixtures.livePayoutAccount,
        terms: CollectiblesBuybackTerms = Fixtures.terms()
    ) -> SUT {
        SUT(owner: owner, usdcMint: usdcMint, payoutAccount: payoutAccount, terms: terms)
    }
}

private extension CollectiblesPreparedTransaction {
    func with(
        signatures: [Data]? = nil,
        header: Header? = nil,
        instructions: [Instruction]? = nil
    ) -> CollectiblesPreparedTransaction {
        CollectiblesPreparedTransaction(
            transactionID: transactionID,
            signatures: signatures ?? self.signatures,
            message: message,
            header: header ?? self.header,
            accountKeys: accountKeys,
            instructions: instructions ?? self.instructions
        )
    }

    func replacingInstruction(at index: Int, with instruction: Instruction) -> CollectiblesPreparedTransaction {
        var instructions = instructions
        instructions[index] = instruction
        return with(instructions: instructions)
    }

    func removingInstruction(at index: Int) -> CollectiblesPreparedTransaction {
        var instructions = instructions
        instructions.remove(at: index)
        return with(instructions: instructions)
    }

    func replacingAccount(at slot: Int, ofInstruction index: Int, with keyIndex: Int) -> Self {
        let instruction = instructions[index]
        var accountIndices = instruction.accountIndices
        accountIndices[slot] = keyIndex
        let replaced = Instruction(
            programIndex: instruction.programIndex,
            accountIndices: accountIndices,
            data: instruction.data
        )
        return replacingInstruction(at: index, with: replaced)
    }

    func replacingData(_ data: Data, ofInstruction index: Int) -> Self {
        let instruction = instructions[index]
        let replaced = Instruction(
            programIndex: instruction.programIndex,
            accountIndices: instruction.accountIndices,
            data: data
        )
        return replacingInstruction(at: index, with: replaced)
    }
}
