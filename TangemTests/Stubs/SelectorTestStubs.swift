//
//  SelectorTestStubs.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation
import TangemPay
@testable import Tangem

final class SelectorUserWalletModelStub: UserWalletModelMock {
    private let id: UserWalletId
    private let isLocked: Bool
    private let manager: SelectorAccountModelsManagerStub

    private var currentName: String
    private let updateSubject = PassthroughSubject<UpdateResult, Never>()

    let totalBalanceSubject: CurrentValueSubject<TotalBalanceState, Never>

    init(
        idSeed: String,
        isLocked: Bool = false,
        totalBalance: TotalBalanceState = .loading(cached: nil),
        accountModelsManager: SelectorAccountModelsManagerStub
    ) {
        id = UserWalletId(value: Data(idSeed.utf8))
        currentName = id.stringValue
        self.isLocked = isLocked
        totalBalanceSubject = CurrentValueSubject(totalBalance)
        manager = accountModelsManager
    }

    override var userWalletId: UserWalletId { id }
    override var name: String { currentName }
    override var isUserWalletLocked: Bool { isLocked }
    override var config: UserWalletConfig { UserWalletConfigStub() }
    override var accountModelsManager: AccountModelsManager { manager }
    override var totalBalancePublisher: AnyPublisher<TotalBalanceState, Never> { totalBalanceSubject.eraseToAnyPublisher() }
    override var updatePublisher: AnyPublisher<UpdateResult, Never> { updateSubject.eraseToAnyPublisher() }

    func rename(to name: String) {
        currentName = name
        updateSubject.send(.nameDidChange(name: name))
    }
}

func makeLockedUserWalletModel(idSeed: String) -> LockedUserWalletModel {
    let mobileWalletInfo = MobileWalletInfo(
        hasMnemonicBackup: false,
        hasICloudBackup: false,
        hasSocialLogin: false,
        accessCodeStatus: .none,
        keys: []
    )

    return LockedUserWalletModel(
        with: StoredUserWallet(userWalletId: Data(idSeed.utf8), name: idSeed, walletInfo: .mobileWallet(mobileWalletInfo))
    )
}

final class SelectorAccountModelsManagerStub: AccountModelsManager {
    private let accountModelsSubject: CurrentValueSubject<[AccountModel], Never>

    init(accountModels: [AccountModel]) {
        accountModelsSubject = CurrentValueSubject(accountModels)
    }

    func send(_ accountModels: [AccountModel]) {
        accountModelsSubject.send(accountModels)
    }

    var canAddCryptoAccounts: Bool { true }
    var accountModels: [AccountModel] { accountModelsSubject.value }
    var accountModelsPublisher: AnyPublisher<[AccountModel], Never> { accountModelsSubject.eraseToAnyPublisher() }
    var hasArchivedCryptoAccountsPublisher: AnyPublisher<Bool, Never> { .just(output: false) }
    var hasSyncedWithRemotePublisher: AnyPublisher<Bool, Never> { .just(output: true) }
    var totalCryptoAccountsCountPublisher: AnyPublisher<Int, Never> { .just(output: accountModels.cryptoAccountsCount) }
    var totalJointAccountsCountPublisher: AnyPublisher<Int, Never> { .just(output: 0) }

    func addCryptoAccount(name: String, icon: AccountModel.CompositeIcon) async throws(AccountEditError) -> AccountCreationResult {
        throw .tooManyAccounts
    }

    func addJointAccount(context: JointAccountCreationContextType) async throws(AccountEditError) -> AccountCreationResult {
        throw .tooManyAccounts
    }

    func joinJointAccount(context: JointAccountJoinContext) async throws(AccountEditError) -> AccountCreationResult {
        throw .tooManyAccounts
    }

    func archivedCryptoAccountInfos() async throws(AccountModelsManagerError) -> [ArchivedCryptoAccountInfo] {
        []
    }

    func unarchiveCryptoAccount(info: ArchivedCryptoAccountInfo) async throws(AccountRecoveryError) -> AccountOperationResult {
        throw .tooManyAccounts
    }

    func reloadAccountsFromRemote() async {}
    func authorizeTangemPayOfferForResidency(authorizingInteractor: any TangemPayAuthorizing) async -> (any TangemPayResidencyInteractor)? { nil }
    func acceptTangemPayCampaignOffer(authorizingInteractor: TangemPayAuthorizing, campaignKey: String) async {}
    func reorder(orderedIdentifiers: [any AccountModelPersistentIdentifierConvertible]) async throws {}
    func dispose() {}
}

func withSelectorDependencies<T>(
    userWalletModels: [any UserWalletModel],
    operation: () async throws -> T
) async rethrows -> T {
    try await InjectedDependenciesIsolation.shared.run {
        let repository = FakeUserWalletRepository(models: userWalletModels)

        let previousRepository = InjectedValues[\.userWalletRepository]
        InjectedValues[\.userWalletRepository] = repository
        defer { InjectedValues[\.userWalletRepository] = previousRepository }

        return try await operation()
    }
}

extension Publisher where Failure == Never {
    var bufferedValues: AsyncPublisher<Publishers.Buffer<Self>> {
        buffer(size: .max, prefetch: .keepFull, whenFull: .dropOldest).values
    }
}
