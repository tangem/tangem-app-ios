//
//  TokenActionAvailabilityProviderJointAccountTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import BlockchainSdk
import TangemFoundation
@testable import Tangem

@Suite("Tests for the actions a joint account's token holds back as coming soon")
struct TokenActionAvailabilityProviderJointAccountTests {
    private let delegate = JointAccountModelDelegateMock()

    @Test("Sell on a joint account's token is coming soon rather than available")
    func sellOnJointAccountTokenIsComingSoon() {
        let sut = makeSUT(account: makeJointAccount())

        guard case .jointAccountsComingSoon = sut.sellAvailability else {
            Issue.record("Expected .jointAccountsComingSoon, got \(sut.sellAvailability)")
            return
        }

        #expect(!sut.isSellAvailable)
    }

    @Test("Sell on a joint account's token is answered with an alert, like swap")
    func sellOnJointAccountTokenIsAnsweredWithAnAlert() {
        let builder = TokenActionAvailabilityAlertBuilder()
        let status = TokenActionAvailabilityProvider.SellActionAvailabilityStatus.jointAccountsComingSoon

        #expect(builder.alert(for: status) != nil)
    }

    @Test("Sell on a personal account's token is not held back as coming soon")
    func sellOnPersonalAccountTokenIsNotComingSoon() {
        let sut = makeSUT(account: nil)

        if case .jointAccountsComingSoon = sut.sellAvailability {
            Issue.record("A personal account's token must not be held back as coming soon")
        }
    }

    @Test("The sell token selector keeps a joint token tappable to explain itself and the other refusals inert")
    func sellSelectorKeepsJointTokenTappable() {
        let comingSoon = TokenSelectorItem.AvailabilityType.unavailable(reason: .unavailableForSell(.jointAccountsComingSoon))
        let emptyBalance = TokenSelectorItem.AvailabilityType.unavailable(reason: .unavailableForSell(.zeroWalletBalance))

        #expect(!comingSoon.disablesTap)
        #expect(emptyBalance.disablesTap)
    }
}

// MARK: - Helpers

private extension TokenActionAvailabilityProviderJointAccountTests {
    func makeSUT(account: (any CryptoAccountModel)?) -> TokenActionAvailabilityProvider {
        TokenActionAvailabilityProvider(
            userWalletInfo: makeUserWalletInfo(),
            walletModel: WalletModelTestsMock(
                tokenItem: .blockchain(.init(.polygon(testnet: false), derivationPath: nil)),
                isEmpty: false,
                account: account
            )
        )
    }

    func makeUserWalletInfo() -> UserWalletInfo {
        UserWalletInfo(
            name: "Test",
            id: UserWalletId(value: Data([0x01])),
            config: UserWalletConfigStub(supportedBlockchains: [.polygon(testnet: false)]),
            backupState: .valid,
            refcode: nil,
            signerFactory: TangemSignerFactory(),
            emailDataProvider: EmailDataProviderStub()
        )
    }

    func makeJointAccount() -> any JointAccountModel {
        CommonJointAccountModel(
            cryptoAccount: CryptoAccountModelMock(isMainAccount: false, accountType: .joint, onArchive: { _ in }),
            derivationIdentity: CryptoAccountDerivationIdentity(derivationIndex: 1, type: .joint),
            accountPolicy: JointAccountPolicy(membersCount: 2, signersCount: 2),
            accountStatus: .pending,
            operationsService: JointAccountOperationsServiceMock(),
            pendingOperationsProvider: JointAccountPendingOperationsProviderMock(),
            membersService: JointAccountMembersServiceMock(),
            delegate: delegate
        )
    }
}
