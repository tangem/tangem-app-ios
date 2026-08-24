//
//  ForYouAccountSelectorTestSupport.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk
import TangemFoundation
import TangemPay
@testable import Tangem

// MARK: - UserWalletModel stub

/// Canned identity, lock state, config, and account manager on top of the shared `UserWalletModelMock`,
/// with the mock's `fatalError` members stubbed out.
final class ForYouWalletModelStub: UserWalletModelMock {
    private let id: UserWalletId
    private let stubbedName: String
    private let isLocked: Bool
    private let stubbedAccountModelsManager: AccountModelsManager

    init(
        idSeed: String,
        name: String,
        isLocked: Bool,
        accountModelsManager: AccountModelsManager
    ) {
        id = UserWalletId(value: Data(idSeed.utf8))
        stubbedName = name
        self.isLocked = isLocked
        stubbedAccountModelsManager = accountModelsManager
    }

    override var userWalletId: UserWalletId { id }
    override var name: String { stubbedName }
    override var isUserWalletLocked: Bool { isLocked }
    override var config: UserWalletConfig { UserWalletConfigStub() }
    override var accountModelsManager: AccountModelsManager { stubbedAccountModelsManager }
}

// MARK: - AccountModelsManager stub

/// Serves a mutable list of crypto accounts through the `AccountModelsManager` publishers.
final class ForYouAccountsManagerStub: AccountModelsManager {
    private let accountsSubject: CurrentValueSubject<[any CryptoAccountModel], Never>

    init(accounts: [any CryptoAccountModel]) {
        accountsSubject = .init(accounts)
    }

    /// Re-emits a new account composition — drives the resolver's reactive rebuild.
    func setAccounts(_ accounts: [any CryptoAccountModel]) {
        accountsSubject.send(accounts)
    }

    private static func wrap(_ accounts: [any CryptoAccountModel]) -> [AccountModel] {
        accounts.isEmpty ? [] : [.standard(.multiple(accounts))]
    }

    var canAddCryptoAccounts: Bool { true }
    var hasArchivedCryptoAccountsPublisher: AnyPublisher<Bool, Never> { .just(output: false) }
    var hasSyncedWithRemotePublisher: AnyPublisher<Bool, Never> { .just(output: true) }

    var accountModels: [AccountModel] { Self.wrap(accountsSubject.value) }

    var accountModelsPublisher: AnyPublisher<[AccountModel], Never> {
        accountsSubject.map { Self.wrap($0) }.eraseToAnyPublisher()
    }

    var totalCryptoAccountsCountPublisher: AnyPublisher<Int, Never> {
        accountsSubject.map(\.count).eraseToAnyPublisher()
    }

    func addCryptoAccount(name: String, icon: AccountModel.CompositeIcon) async throws(AccountEditError) -> AccountOperationResult {
        throw .tooManyAccounts
    }

    func addJointAccount(context: JointAccountCreationContext) async throws(AccountEditError) {
        throw .tooManyAccounts
    }

    func archivedCryptoAccountInfos() async throws(AccountModelsManagerError) -> [ArchivedCryptoAccountInfo] {
        []
    }

    func unarchiveCryptoAccount(info: ArchivedCryptoAccountInfo) async throws(AccountRecoveryError) -> AccountOperationResult {
        throw .tooManyAccounts
    }

    func acceptTangemPayOffer(authorizingInteractor: TangemPayAuthorizing) async {}
    func reorder(orderedIdentifiers: [any AccountModelPersistentIdentifierConvertible]) async throws {}
    func dispose() {}
}

// MARK: - Action recorder

/// Records the sheet/chip view model's apply/dismiss/reset outputs.
final class ForYouSelectorActionRecorder {
    private(set) var appliedSelections: [ForYouAccountSelection] = []
    private(set) var dismissCallCount = 0
    private(set) var resetCallCount = 0

    func apply(_ selection: ForYouAccountSelection) {
        appliedSelections.append(selection)
    }

    func dismiss() {
        dismissCallCount += 1
    }

    func reset() {
        resetCallCount += 1
    }
}
