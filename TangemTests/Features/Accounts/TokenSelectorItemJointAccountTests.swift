//
//  TokenSelectorItemJointAccountTests.swift
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

@Suite("A joint account's token in the token selector")
struct TokenSelectorItemJointAccountTests {
    private let delegate = JointAccountModelDelegateMock()

    @Test("Can be swapped into but never swapped from")
    func jointAccountTokenIsReceiveOnly() throws {
        let item = makeJointItem()
        let builder = TokenSelectorItemOutputTypeBuilder(expressOperationType: .swap)

        let receiveToken = try builder.makeReceiveToken(item: item)

        #expect(receiveToken is SendSourceToken)
        #expect(!(receiveToken is SendSwapableToken))
        #expect(throws: WalletModelSendTokenFactory.BuildError.self) {
            try builder.makeSwapableToken(item: item)
        }
    }

    @Test("A joint account's token refused as the source explains it with its source status")
    func jointAccountTokenAsSourceCarriesItsSourceStatus() throws {
        let builder = TokenSelectorItemOutputTypeBuilder(expressOperationType: .swap)

        let error = try #require(throws: WalletModelSendTokenFactory.BuildError.self) {
            try builder.makeSwapableToken(item: makeJointItem())
        }

        switch error {
        case .receiveOnlyToken(_, let sourceAvailability):
            #expect(sourceAvailability.isJointAccountsComingSoon)
        }
    }

    @Test("Reports the participant's incomplete backup as a receive restriction")
    func jointAccountTokenReportsIncompleteBackup() async throws {
        let item = makeJointItem(backupState: .incompleteBackup)

        let restriction = try await makeReceiveRestriction(item: item)

        guard case .incompleteBackup = restriction else {
            Issue.record("Expected .incompleteBackup, got \(String(describing: restriction))")
            return
        }
    }

    @Test("Reports no receive restriction when the participant's backup is valid")
    func jointAccountTokenReportsNoRestrictionWithValidBackup() async throws {
        let item = makeJointItem()

        let restriction = try await makeReceiveRestriction(item: item)

        #expect(restriction == nil)
    }
}

// MARK: - Helpers

private extension TokenSelectorItemJointAccountTests {
    func makeWalletModel(account: any CryptoAccountModel) -> WalletModelTestsMock {
        WalletModelTestsMock(
            tokenItem: .blockchain(.init(.polygon(testnet: false), derivationPath: nil)),
            isEmpty: false,
            account: account
        )
    }

    func makeJointItem(backupState: UserWalletBackupState = .valid) -> TokenSelectorItem {
        let jointAccount = makeJointAccount()

        return TokenSelectorItem(
            userWalletInfo: makeUserWalletInfo(backupState: backupState),
            kind: .crypto(makeWalletModel(account: jointAccount), jointAccount)
        )
    }

    func makeReceiveRestriction(item: TokenSelectorItem) async throws -> ReceivedRestriction? {
        let receiveToken = try TokenSelectorItemOutputTypeBuilder(expressOperationType: .swap).makeReceiveToken(item: item)

        guard let sourceToken = receiveToken as? SendSourceToken else {
            Issue.record("Expected a SendSourceToken, got \(type(of: receiveToken))")
            return nil
        }

        return try await sourceToken.receivingRestrictionsProvider.restriction(expectAmount: .zero)
    }

    func makeUserWalletInfo(backupState: UserWalletBackupState = .valid) -> UserWalletInfo {
        UserWalletInfo(
            name: "Test",
            id: UserWalletId(value: Data([0x01])),
            config: UserWalletConfigStub(supportedBlockchains: [.polygon(testnet: false)]),
            backupState: backupState,
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
