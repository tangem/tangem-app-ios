//
//  JointAccountActivationTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

// MARK: - Tests

/// What the creator's activation is asked for with, and what is refused before the wallet is asked for anything.
@Suite("Tests for activating a joint account")
struct JointAccountActivationTests {
    /// Kept by the suite because the accounts hold it weakly, and a new one is made per test the way every stored
    /// property of a suite is.
    private let delegate = JointAccountModelDelegateMock()

    @Test("The activation carries the checked composition, with the address spelled as the backend announced it")
    func activationCarriesTheCheckedComposition() async throws {
        let cryptoAccount = CryptoAccountModelMock(isMainAccount: false, onArchive: { _ in })
        let account = makeJointAccount(
            // The backend keeps the address in lower case and compares the config it holds character by character,
            // so the app signs over that spelling rather than the checksummed form it computes
            status: .confirming(safeAddress: Constants.announcedSafeAddress.lowercased()),
            members: Constants.fullComposition,
            cryptoAccount: cryptoAccount
        )

        try await account.activate()

        let config = try #require(delegate.activationConfigs.first)

        #expect(delegate.activationConfigs.count == 1)
        #expect(config.safeAddress == Constants.announcedSafeAddress.lowercased())
        #expect(config.creatorAddress == Constants.owners[0])
        #expect(config.derivationIndex == Constants.derivationIdentity.derivationIndex)
        #expect(config.cryptoAccountId == cryptoAccount.id.rawValue.hexString)
        #expect(config.signedConfig.name == cryptoAccount.name)
        #expect(config.signedConfig.icon == cryptoAccount.icon.name.rawValue)
        #expect(config.signedConfig.iconColor == cryptoAccount.icon.color.rawValue)
        #expect(config.signedConfig.membersCount == Constants.owners.count)
        #expect(config.signedConfig.threshold == Constants.threshold)
    }

    /// The button is offered without one — see `JointAccountStateTests` — so pressing it is what has to
    /// report that the answer named no address to confirm.
    @Test("An account with no announced address has nothing to activate with")
    func activationWithoutAnAnnouncedAddressIsRefused() async {
        let account = makeJointAccount(status: .confirming(safeAddress: nil), members: Constants.fullComposition)

        let error = await activationError(of: account)

        #expect(error as? JointAccountModelError == .notReadyForActivation)
        #expect(delegate.activationConfigs.isEmpty)
    }

    @Test("An account that names no creator among its members has no slot to activate from")
    func activationWithoutACreatorIsRefused() async {
        let account = makeJointAccount(
            status: .confirming(safeAddress: Constants.announcedSafeAddress),
            members: Constants.owners.enumerated().map { index, address in
                JointAccountMember(name: "Member \(index)", address: address, role: .member(inviteId: "invite-\(index)"))
            }
        )

        let error = await activationError(of: account)

        #expect(error as? JointAccountModelError == .notReadyForActivation)
        #expect(delegate.activationConfigs.isEmpty)
    }

    @Test("A composition that does not resolve to the announced address is refused before anything is signed")
    func activationOfAnotherCompositionIsRefused() async {
        let account = makeJointAccount(
            // The address of the same members under a threshold of three
            status: .confirming(safeAddress: Constants.announcedSafeAddress),
            members: Constants.fullComposition,
            threshold: 3
        )

        let error = await activationError(of: account)

        #expect(error as? JointAccountSafeAddressVerifier.VerificationError == .addressMismatch)
        #expect(delegate.activationConfigs.isEmpty)
    }

    @Test("An account the wallet has already let go of refuses to activate rather than reporting that it has")
    func activationWithoutTheWalletThatRunsItIsRefused() async {
        var goneDelegate: JointAccountModelDelegateMock? = JointAccountModelDelegateMock()
        let account = makeJointAccount(
            status: .confirming(safeAddress: Constants.announcedSafeAddress),
            members: Constants.fullComposition,
            delegate: goneDelegate
        )

        goneDelegate = nil

        let error = await activationError(of: account)

        #expect(error as? JointAccountModelError == .activationUnavailable)
    }

    @Test("What the wallet reports the activation with reaches whoever asked for it")
    func activationFailureIsReported() async {
        delegate.failActivation(with: .duplicateAccountName)
        let account = makeJointAccount(
            status: .confirming(safeAddress: Constants.announcedSafeAddress),
            members: Constants.fullComposition
        )

        do throws(AccountEditError) {
            try await account.activate()
            Issue.record("The activation was reported as done")
        } catch .duplicateAccountName {
            // The error the wallet reported, passed on as it was
        } catch {
            Issue.record("The activation failed with \(error) instead")
        }

        #expect(delegate.activationConfigs.count == 1)
    }
}

// MARK: - Helpers

private extension JointAccountActivationTests {
    /// - Returns: What the activation failed with, unwrapped out of `AccountEditError.unknownError` because that is
    /// how the joint account reports everything of its own, or `nil` when it went through.
    func activationError(of account: any JointAccountModel) async -> (any Error)? {
        do throws(AccountEditError) {
            try await account.activate()
            return nil
        } catch {
            guard case .unknownError(let underlyingError) = error else {
                return error
            }

            return underlyingError
        }
    }

    func makeJointAccount(
        status: JointAccountStatus,
        members: [JointAccountMember],
        threshold: Int = Constants.threshold,
        cryptoAccount: CryptoAccountModelMock = CryptoAccountModelMock(isMainAccount: false, onArchive: { _ in }),
        delegate: (any JointAccountModelDelegate)? = nil
    ) -> any JointAccountModel {
        CommonJointAccountModel(
            cryptoAccount: cryptoAccount,
            derivationIdentity: Constants.derivationIdentity,
            accountPolicy: JointAccountPolicy(membersCount: Constants.owners.count, signersCount: threshold),
            accountStatus: status,
            operationsService: JointAccountOperationsServiceMock(),
            pendingOperationsProvider: JointAccountPendingOperationsProviderMock(),
            membersService: JointAccountMembersServiceMock(slots: members.map(JointAccountSlot.member)),
            delegate: delegate ?? self.delegate
        )
    }
}

// MARK: - Constants

private extension JointAccountActivationTests {
    enum Constants {
        static let threshold = 2
        static let derivationIdentity = CryptoAccountDerivationIdentity(derivationIndex: 1, type: .joint)

        /// The owners of the Safe at `announcedSafeAddress` under a threshold of two — see
        /// `JointAccountSafeAddressVerifierTests`.
        static let owners = [
            "0xa9936482d7d056d6f843f5C6088Ff0123b796bCC",
            "0xB8C09e7abE7e0F70f4F4cAf48eED46cc8BfdA120",
            "0xD048326c01787c475Af00C51eb0221d2557bfEc2",
        ]

        static let announcedSafeAddress = "0x9295a5836685C5F5f42242f9B64d23E46F8c259F"

        /// Every slot taken, the creator's first, as the account reports them once it is waiting to be activated.
        static var fullComposition: [JointAccountMember] {
            owners.enumerated().map { index, address in
                JointAccountMember(
                    name: "Member \(index)",
                    address: address,
                    role: index == 0 ? .creator : .member(inviteId: "invite-\(index)")
                )
            }
        }
    }
}
