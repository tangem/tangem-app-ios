//
//  AccountModelsManagerMock.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

final class AccountModelsManagerMock {
    private let walletModelsManager: WalletModelsManager
    private let totalBalanceProvider: any TotalBalanceProvider
    private let userTokensManager: UserTokensManager

    private let accountModelsSubject = CurrentValueSubject<[AccountModel], Never>([])
    private let totalAccountsCountSubject = CurrentValueSubject<Int, Never>(0)
    private let hasArchivedCryptoAccountsSubject = CurrentValueSubject<Bool, Never>(false)

    private var cryptoAccountModels: [CryptoAccountModelMock] = [] {
        didSet {
            let cryptoAccountsBuilder = CryptoAccountsBuilder(globalState: .single)
            let cryptoAccounts = cryptoAccountsBuilder.build(from: cryptoAccountModels)
            accountModelsSubject.send([.standard(cryptoAccounts)])
            totalAccountsCountSubject.send(cryptoAccountModels.count)
        }
    }

    init(
        walletModelsManager: WalletModelsManager = WalletModelsManagerMock(),
        totalBalanceProvider: any TotalBalanceProvider = TotalBalanceProviderMock(),
        userTokensManager: UserTokensManager = UserTokensManagerMock(),
    ) {
        self.walletModelsManager = walletModelsManager
        self.totalBalanceProvider = totalBalanceProvider
        self.userTokensManager = userTokensManager

        // `defer` is used to trigger the `didSet` observer
        defer {
            let mainAccount = CryptoAccountModelMock(
                isMainAccount: true,
                walletModelsManager: walletModelsManager,
                totalBalanceProvider: totalBalanceProvider,
                userTokensManager: userTokensManager,
            )

            let secondAccount = CryptoAccountModelMock(
                isMainAccount: false,
                walletModelsManager: walletModelsManager,
                totalBalanceProvider: totalBalanceProvider,
                userTokensManager: userTokensManager
            )

            cryptoAccountModels = [mainAccount, secondAccount]
        }
    }

    func removeCryptoAccount(withIdentifier identifier: some Hashable) async throws {
        cryptoAccountModels.removeAll { $0.id.toPersistentIdentifier().toAnyHashable() == identifier.toAnyHashable() }
    }
}

// MARK: - AccountModelsManager protocol conformance

extension AccountModelsManagerMock: AccountModelsManager {
    var hasMultipleAccounts: Bool {
        true
    }

    var canAddCryptoAccounts: Bool {
        true
    }

    var hasArchivedCryptoAccounts: AnyPublisher<Bool, Never> {
        hasArchivedCryptoAccountsSubject
            .eraseToAnyPublisher()
    }

    var totalAccountsCountPublisher: AnyPublisher<Int, Never> {
        totalAccountsCountSubject.eraseToAnyPublisher()
    }

    var accountModels: [AccountModel] {
        accountModelsSubject.value
    }

    var accountModelsPublisher: AnyPublisher<[AccountModel], Never> {
        accountModelsSubject.eraseToAnyPublisher()
    }

    func addCryptoAccount(name: String, icon: AccountModel.Icon) async throws(AccountModelsManagerError) {
        cryptoAccountModels.append(CryptoAccountModelMock(isMainAccount: false, walletModelsManager: walletModelsManager))
    }

    func archivedCryptoAccountInfos() async throws(AccountModelsManagerError) -> [ArchivedCryptoAccountInfo] {
        try? await Task.sleep(seconds: 2) // simulate network call
        try? Task.checkCancellation()

        return [
            ArchivedCryptoAccountInfo(
                accountId: .init(rawValue: UUID().uuidString),
                name: "Archived crypto account #1",
                icon: .init(name: .allCases.randomElement()!, color: .allCases.randomElement()!),
                tokensCount: 3,
                networksCount: 1,
                derivationIndex: 10
            ),
            ArchivedCryptoAccountInfo(
                accountId: .init(rawValue: UUID().uuidString),
                name: "Archived crypto account #2",
                icon: .init(name: .allCases.randomElement()!, color: .allCases.randomElement()!),
                tokensCount: 10,
                networksCount: 10,
                derivationIndex: 20
            ),
        ]
    }

    func archiveCryptoAccount(
        withIdentifier identifier: any AccountModelPersistentIdentifierConvertible
    ) async throws(AccountArchivationError) {
        do {
            try await Task.sleep(seconds: 2) // simulate network call
            try Task.checkCancellation()
            try await removeCryptoAccount(withIdentifier: identifier.toPersistentIdentifier())
            hasArchivedCryptoAccountsSubject.send(true)
        } catch {
            throw .unknownError(error)
        }
    }

    func unarchiveCryptoAccount(info: ArchivedCryptoAccountInfo) async throws(AccountRecoveryError) {
        do {
            let persistentConfig = info.toPersistentConfig()
            let isMainAccount = AccountModelUtils.isMainAccount(persistentConfig.derivationIndex)
            let unarchivedCryptoAccount = CryptoAccountModelMock(isMainAccount: isMainAccount)

            try await Task.sleep(seconds: 2) // simulate network call
            try Task.checkCancellation()

            unarchivedCryptoAccount.setIcon(info.icon)
            unarchivedCryptoAccount.setName(info.name)
            cryptoAccountModels.append(unarchivedCryptoAccount)
        } catch {
            throw .unknownError(error)
        }
    }
}
