//
//  JointAccountPendingOperationTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import Testing
import BlockchainSdk
@testable import Tangem

@Suite("Tests for where a member stands on an operation of their joint account")
struct JointAccountPendingOperationTests {
    private let delegate = JointAccountModelDelegateMock()

    @Test("A member who has not answered has no decision yet, and may sign or decline")
    func memberWithoutAnAnswerHasNoDecisionYet() throws {
        let pendingOperation = try makePendingOperation(signatures: [Self.creatorSignature])

        #expect(pendingOperation.standing == .noDecisionYet)
        #expect(pendingOperation.canSign)
        #expect(pendingOperation.canReject)
    }

    @Test("A member who signed stands as signed, with nothing left to sign, though they may still decline")
    func memberWhoSignedStandsAsSigned() throws {
        let pendingOperation = try makePendingOperation(signatures: [Self.creatorSignature, Self.ownSignature(.signed)])

        #expect(pendingOperation.standing == .signed)
        #expect(!pendingOperation.canSign)
        #expect(pendingOperation.canReject)
    }

    @Test("A member who declined stands as declined, with nothing left to answer")
    func memberWhoDeclinedStandsAsDeclined() throws {
        let pendingOperation = try makePendingOperation(signatures: [Self.creatorSignature, Self.ownSignature(.declined)])

        #expect(pendingOperation.standing == .declined)
        #expect(!pendingOperation.canSign)
        #expect(!pendingOperation.canReject)
    }

    @Test("The initiator stands as signed by creating the operation, and may still call it off")
    func initiatorStandsAsSigned() throws {
        let pendingOperation = try makePendingOperation(initiator: Constants.ownAddress, signatures: [])

        #expect(pendingOperation.initiator.isMe)
        #expect(pendingOperation.standing == .signed)
        #expect(!pendingOperation.canSign)
        #expect(pendingOperation.canReject)
    }

    @Test("An answer this version cannot read leaves nothing to sign, though the member may still decline")
    func unreadableAnswerLeavesNothingToSign() throws {
        let pendingOperation = try makePendingOperation(signatures: [Self.ownSignature(.unknown)])

        #expect(pendingOperation.standing == .unreadable)
        #expect(!pendingOperation.canSign)
        #expect(pendingOperation.canReject)
    }

    @Test("Addresses are matched whichever case either side spells them in")
    func addressesAreMatchedRegardlessOfCase() throws {
        let signature = JointAccountOperation.Signature(address: Constants.ownAddress.uppercased(), state: .signed, at: Constants.signedAt)
        let pendingOperation = try makePendingOperation(initiator: Constants.creatorAddress.uppercased(), signatures: [signature])

        #expect(!pendingOperation.initiator.isMe)
        #expect(pendingOperation.standing == .signed)
        #expect(!pendingOperation.canSign)
    }

    @Test("A wallet whose key of the account is not derived yet has nothing to answer")
    func walletWithoutTheDerivedKeyHasNothingToAnswer() throws {
        let pendingOperation = try makePendingOperation(signatures: [Self.ownSignature(.signed)], hasDerivedKey: false)

        #expect(!pendingOperation.initiator.isMe)
        #expect(pendingOperation.standing == .unavailable)
        #expect(!pendingOperation.canSign)
        #expect(!pendingOperation.canReject)
    }

    @Test(
        "An operation past collecting signatures leaves nothing to answer, whatever the member's standing",
        arguments: [JointAccountOperationStatus.pending, .executed, .failed, .cancelled, .unknown]
    )
    func operationPastSigningLeavesNothingToAnswer(status: JointAccountOperationStatus) throws {
        let pendingOperation = try makePendingOperation(status: status, signatures: [Self.creatorSignature])

        #expect(pendingOperation.standing == .noDecisionYet)
        #expect(!pendingOperation.canSign)
        #expect(!pendingOperation.canReject)
    }
}

// MARK: - Fixtures

private extension JointAccountPendingOperationTests {
    static let creatorSignature = JointAccountOperation.Signature(address: Constants.creatorAddress, state: .signed, at: Constants.signedAt)

    static func ownSignature(_ state: JointAccountOperation.Signature.State) -> JointAccountOperation.Signature {
        JointAccountOperation.Signature(address: Constants.ownAddress, state: state, at: Constants.signedAt)
    }

    func makePendingOperation(
        status: JointAccountOperationStatus = .awaitingSignatures,
        initiator: String = Constants.creatorAddress,
        signatures: [JointAccountOperation.Signature],
        hasDerivedKey: Bool = true
    ) throws -> JointAccountPendingOperation {
        let account = CommonJointAccountModel(
            cryptoAccount: CryptoAccountModelMock(isMainAccount: false, onArchive: { _ in }),
            derivationIdentity: JointAccountCompositionFixture.derivationIdentity,
            accountPolicy: JointAccountPolicy(membersCount: 2, signersCount: 2),
            statusProvider: JointAccountStatusProviderStub(status: .active(safeAddress: Constants.safeAddress)),
            operationsService: JointAccountOperationsServiceMock(),
            pendingOperationsProvider: JointAccountPendingOperationsProviderMock(),
            membersService: JointAccountMembersServiceMock(),
            finishedOperationsWalletUpdater: JointAccountFinishedOperationsWalletUpdater(
                pendingOperationsProvider: JointAccountPendingOperationsProviderMock(),
                walletModelsManager: WalletModelsManagerMock(),
                historyDeltaSyncing: JointOperationsHistoryDeltaSyncingStub()
            ),
            userRoleService: JointAccountUserRoleServiceMock(address: hasDerivedKey ? Constants.ownAddress : nil),
            delegate: delegate
        )

        let wallet = try JointAccountWalletBuilder().build(
            walletModel: WalletModelTestsMock(
                tokenItem: Constants.coin,
                isEmpty: false,
                account: account,
                safeWalletManagerOperationsService: SafeWalletManagerOperationsServiceTestsMock()
            )
        )

        let operation = JointAccountCompositionFixture.coinTransfer(status: status, initiator: initiator, signatures: signatures)

        let operationInitiator: JointAccountPendingOperation.Initiator = initiator.caseInsensitiveEquals(to: Constants.ownAddress)
            ? .me
            : .unlisted(address: initiator)

        return JointAccountPendingOperation(
            wallet: wallet,
            initiator: operationInitiator,
            operation: operation,
            innerCallType: .transfer(.coin(destination: Constants.recipient, value: 1_000_000_000_000_000)),
            feeTokenItem: Constants.coin,
            handleProvider: JointAccountPendingOperationHandleProviderStub()
        )
    }

    enum Constants {
        static let coin: TokenItem = .blockchain(BlockchainNetwork(.ethereum(testnet: false), derivationPath: nil))
        static let recipient = "0x2b5ad9c1e7f40638b2c1a9d3e5f70241c6b8a91c"
        static let safeAddress = "0x8f3a1c5e7b9d0246a8c0e2b4d6f8a0c2e4b6c21b"
        static let creatorAddress = "0x7e5fb2c1a9d3e5f70241c6b8a91cd9c1e7f45bdf"
        static let ownAddress = "0x3c9e1b7a5d2f80461c8a0e2b4d6f8a0c2e4b6c90"
        static let signedAt = "2026-10-27T10:00:00Z"
    }
}
