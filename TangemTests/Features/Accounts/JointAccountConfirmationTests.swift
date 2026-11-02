//
//  JointAccountConfirmationTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

// MARK: - Tests

/// What a member's confirmation is asked for with, and what is refused before the wallet is asked for anything.
@Suite("Tests for confirming a joint account")
struct JointAccountConfirmationTests {
    /// Kept by the suite because the accounts hold it weakly, and a new one is made per test the way every stored
    /// property of a suite is.
    private let delegate = JointAccountModelDelegateMock()

    @Test("The confirmation carries the account's settings and the shown address, spelled as the backend announced it")
    func confirmationCarriesTheSettingsAndTheShownAddress() async throws {
        let cryptoAccount = CryptoAccountModelMock(isMainAccount: false, onArchive: { _ in })
        let account = makeJointAccount(
            // The backend keeps the address in lower case and compares the config it holds character by character,
            // so the app signs over that spelling rather than the checksummed form it computes
            status: .confirming(safeAddress: Constants.announcedSafeAddress.lowercased()),
            members: Constants.fullComposition,
            cryptoAccount: cryptoAccount
        )

        try await account.confirm(safeAddress: Constants.announcedSafeAddress.lowercased())

        let config = try #require(delegate.confirmationConfigs.first)

        #expect(delegate.confirmationConfigs.count == 1)
        #expect(config.safeAddress == Constants.announcedSafeAddress.lowercased())
        #expect(config.derivationIndex == Constants.derivationIdentity.derivationIndex)
        #expect(config.signedConfig.name == cryptoAccount.name)
        #expect(config.signedConfig.icon == cryptoAccount.icon.name.rawValue)
        #expect(config.signedConfig.iconColor == cryptoAccount.icon.color.rawValue)
        #expect(config.signedConfig.membersCount == Constants.owners.count)
        #expect(config.signedConfig.threshold == Constants.threshold)
    }

    @Test("An account with no announced address has nothing to confirm")
    func confirmationWithoutAnAnnouncedAddressIsRefused() async {
        let account = makeJointAccount(status: .confirming(safeAddress: nil), members: Constants.fullComposition)

        let error = await confirmationError(of: account)

        #expect(error as? JointAccountModelError == .notReadyForConfirmation)
        #expect(delegate.confirmationConfigs.isEmpty)
    }

    @Test("An address other than the one the account carries now is not confirmed")
    func confirmationOfAnotherAddressIsRefused() async {
        let account = makeJointAccount(
            status: .confirming(safeAddress: Constants.announcedSafeAddress),
            members: Constants.fullComposition
        )

        let error = await confirmationError(of: account, safeAddress: Constants.otherSafeAddress)

        #expect(error as? JointAccountModelError == .addressChanged)
        #expect(delegate.confirmationConfigs.isEmpty)
    }

    @Test("An account the wallet has already let go of refuses to confirm rather than reporting that it has")
    func confirmationWithoutTheWalletThatRunsItIsRefused() async {
        var goneDelegate: JointAccountModelDelegateMock? = JointAccountModelDelegateMock()
        let account = makeJointAccount(
            status: .confirming(safeAddress: Constants.announcedSafeAddress),
            members: Constants.fullComposition,
            delegate: goneDelegate
        )

        goneDelegate = nil

        let error = await confirmationError(of: account)

        #expect(error as? JointAccountModelError == .confirmationUnavailable)
    }

    @Test("What the wallet reports the confirmation with reaches whoever asked for it")
    func confirmationFailureIsReported() async {
        delegate.failConfirmation(with: .duplicateAccountName)
        let account = makeJointAccount(
            status: .confirming(safeAddress: Constants.announcedSafeAddress),
            members: Constants.fullComposition
        )

        do throws(AccountEditError) {
            try await account.confirm(safeAddress: Constants.announcedSafeAddress)
            Issue.record("The confirmation was reported as done")
        } catch .duplicateAccountName {
            // The error the wallet reported, passed on as it was
        } catch {
            Issue.record("The confirmation failed with \(error) instead")
        }

        #expect(delegate.confirmationConfigs.count == 1)
    }
}

// MARK: - Helpers

private extension JointAccountConfirmationTests {
    /// - Returns: What the confirmation failed with, unwrapped out of `AccountEditError.unknownError` because that is
    /// how the joint account reports everything of its own, or `nil` when it went through.
    func confirmationError(
        of account: any JointAccountModel,
        safeAddress: String = Constants.announcedSafeAddress
    ) async -> (any Error)? {
        do throws(AccountEditError) {
            try await account.confirm(safeAddress: safeAddress)
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
            membersService: JointAccountMembersServiceMock(slots: members.map { .member($0, .joined) }),
            finishedOperationsWalletUpdater: JointAccountFinishedOperationsWalletUpdater(
                pendingOperationsProvider: JointAccountPendingOperationsProviderMock(),
                walletModelsManager: WalletModelsManagerMock()
            ),
            userRoleService: JointAccountUserRoleServiceMock(),
            delegate: delegate ?? self.delegate
        )
    }
}

// MARK: - Constants

private extension JointAccountConfirmationTests {
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
        static let otherSafeAddress = "0x8f3a1c5e7b9d0246a8c0e2b4d6f8a0c2e4b6c21b"

        /// Every slot taken, the creator's first, as the account reports them once it is waiting to be confirmed.
        static var fullComposition: [JointAccountMember] {
            owners.enumerated().map { index, address in
                JointAccountMember(
                    name: "Member \(index)",
                    address: address,
                    role: index == 0 ? .creator : .member,
                    isMe: false,
                    signature: nil
                )
            }
        }
    }
}
