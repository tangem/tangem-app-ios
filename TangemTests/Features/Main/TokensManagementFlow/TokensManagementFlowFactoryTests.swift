//
//  TokensManagementFlowFactoryTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import Testing
import TangemTestKit
import TangemAccounts
import TangemFoundation
@testable import Tangem

@Suite("TokensManagementFlowFactory account picker", .timeLimit(.minutes(1)))
@MainActor
final class TokensManagementFlowFactoryTests: LeakTrackingTestSuite {
    private let delegate = JointAccountModelDelegateMock()

    @Test("The Add tokens picker lists the crypto and active joint accounts of its own user wallet only")
    func pickerListsOwnCryptoAndActiveJointAccounts() async {
        let mainAccount = makeAccount()
        let activeJointAccount = makeJointAccountStub(isActive: true, delegate: delegate)
        let userWallet = makeUserWallet("userWallet", accountModels: [
            .standard(.single(mainAccount)),
            .joint([activeJointAccount, makeJointAccountStub(isActive: false, delegate: delegate)]),
        ])
        let otherUserWallet = makeUserWallet("other", accountModels: [.standard(.single(makeAccount()))])
        let (sut, _) = await makeSUT(userWallet: userWallet, repositoryUserWallets: [otherUserWallet, userWallet])

        let sections = await sections(of: sut) { sections in
            sections.contains { $0.id == userWallet.userWalletId.stringValue && $0.accounts.count == 2 }
        }

        #expect(sections.map(\.id) == [userWallet.userWalletId.stringValue])
        #expect(sections.first?.accounts.map(\.id) == [mainAccount.id.toAnyHashable(), activeJointAccount.id.toAnyHashable()])
    }

    @Test("Picking the joint account hands it to onSelect")
    func pickingJointAccountHandsItToOnSelect() async throws {
        let activeJointAccount = makeJointAccountStub(isActive: true, delegate: delegate)
        let userWallet = makeUserWallet("userWallet", accountModels: [.standard(.single(makeAccount())), .joint([activeJointAccount])])
        let (sut, spy) = await makeSUT(userWallet: userWallet, repositoryUserWallets: [userWallet])

        let jointItem = try #require(await sections(of: sut) { $0.first?.accounts.count == 2 }.first?.accounts.last)
        sut.select(jointItem)

        #expect(spy.accountIds == [activeJointAccount.id.toAnyHashable()])
    }
}

// MARK: - Helpers

private extension TokensManagementFlowFactoryTests {
    func makeSUT(
        userWallet: SelectorUserWalletModelStub,
        repositoryUserWallets: [any UserWalletModel]
    ) async -> (AccountPickerViewModel, AccountSelectionSpy) {
        let spy = AccountSelectionSpy()
        let factory = TokensManagementFlowFactory(userWalletModel: userWallet, analyticsLogger: TokensManagementAnalyticsLogger())
        let sut = await withSelectorDependencies(userWalletModels: repositoryUserWallets, globalState: .multiple) {
            factory.makeAccountPickerViewModel(onSelect: spy.record)
        }

        trackForMemoryLeaks(spy)
        return (trackForMemoryLeaks(sut), spy)
    }

    func sections(
        of sut: AccountPickerViewModel,
        until condition: @escaping ([AccountPickerUserWalletSection]) -> Bool
    ) async -> [AccountPickerUserWalletSection] {
        await sut.$content.bufferedValues
            .compactMap { content -> [AccountPickerUserWalletSection]? in
                guard case .accounts(let sections) = content else { return nil }
                return sections
            }
            .first(where: condition) ?? []
    }

    func makeAccount() -> CryptoAccountModelMock {
        CryptoAccountModelMock(isMainAccount: true, onArchive: { _ in })
    }

    func makeUserWallet(_ idSeed: String, accountModels: [AccountModel]) -> SelectorUserWalletModelStub {
        SelectorUserWalletModelStub(idSeed: idSeed, accountModelsManager: SelectorAccountModelsManagerStub(accountModels: accountModels))
    }
}

// MARK: - Stubs

private final class AccountSelectionSpy {
    private(set) var accountIds: [AnyHashable] = []

    func record(_ account: any CryptoAccountModel) {
        accountIds.append(account.id.toAnyHashable())
    }
}
