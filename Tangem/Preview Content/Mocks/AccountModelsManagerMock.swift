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
            ) { [weak self] cryptoAccountModel in
                Task { try? await self?.archiveCryptoAccount(withIdentifier: cryptoAccountModel.id) }
            }

            let secondAccount = CryptoAccountModelMock(
                isMainAccount: false,
                walletModelsManager: walletModelsManager,
                totalBalanceProvider: totalBalanceProvider,
                userTokensManager: userTokensManager
            ) { [weak self] cryptoAccountModel in
                Task { try? await self?.archiveCryptoAccount(withIdentifier: cryptoAccountModel.id) }
            }

            cryptoAccountModels = [mainAccount, secondAccount]
        }
    }

    private func removeCryptoAccount(withIdentifier identifier: some Hashable) async throws {
        cryptoAccountModels.removeAll { $0.id.toPersistentIdentifier().toAnyHashable() == identifier.toAnyHashable() }
    }

    private func archiveCryptoAccount(
        withIdentifier identifier: any AccountModelPersistentIdentifierConvertible
    ) async throws(AccountArchivationError) {
        do {
            try await Task.sleep(for: .seconds(2)) // simulate network call
            try Task.checkCancellation()
            try await removeCryptoAccount(withIdentifier: identifier.toPersistentIdentifier())
            hasArchivedCryptoAccountsSubject.send(true)
        } catch {
            throw .unknownError(error)
        }
    }
}

// MARK: - AccountModelsManager protocol conformance

extension AccountModelsManagerMock: AccountModelsManager {
    var canAddCryptoAccounts: Bool {
        true
    }

    var hasSyncedWithRemotePublisher: AnyPublisher<Bool, Never> {
        .just(output: true)
    }

    var hasArchivedCryptoAccountsPublisher: AnyPublisher<Bool, Never> {
        hasArchivedCryptoAccountsSubject
            .eraseToAnyPublisher()
    }

    var totalCryptoAccountsCountPublisher: AnyPublisher<Int, Never> {
        totalAccountsCountSubject.eraseToAnyPublisher()
    }

    var accountModels: [AccountModel] {
        accountModelsSubject.value
    }

    var accountModelsPublisher: AnyPublisher<[AccountModel], Never> {
        accountModelsSubject.eraseToAnyPublisher()
    }

    func addCryptoAccount(name: String, icon: AccountModel.Icon) async throws(AccountEditError) -> AccountOperationResult {
        let cryptoAccount = CryptoAccountModelMock(
            isMainAccount: false,
            walletModelsManager: walletModelsManager
        ) { [weak self] cryptoAccountModel in
            Task { try? await self?.archiveCryptoAccount(withIdentifier: cryptoAccountModel.id) }
        }

        cryptoAccountModels.append(cryptoAccount)

        return .none
    }

    func archivedCryptoAccountInfos() async throws(AccountModelsManagerError) -> [ArchivedCryptoAccountInfo] {
        try? await Task.sleep(for: .seconds(2)) // simulate network call
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

    func unarchiveCryptoAccount(info: ArchivedCryptoAccountInfo) async throws(AccountRecoveryError) -> AccountOperationResult {
        do {
            let persistentConfig = info.toPersistentConfig()
            let isMainAccount = AccountModelUtils.isMainAccount(persistentConfig.derivationIndex)
            let unarchivedCryptoAccount = CryptoAccountModelMock(
                isMainAccount: isMainAccount
            ) { [weak self] cryptoAccountModel in
                Task { try? await self?.archiveCryptoAccount(withIdentifier: cryptoAccountModel.id) }
            }

            try await Task.sleep(for: .seconds(2)) // simulate network call
            try Task.checkCancellation()

            try await unarchivedCryptoAccount.edit { editor in
                editor.setName(info.name)
                editor.setIcon(info.icon)
            }
            cryptoAccountModels.append(unarchivedCryptoAccount)

            return .none
        } catch {
            throw .unknownError(error)
        }
    }

    func reorder(orderedIdentifiers: [any AccountModelPersistentIdentifierConvertible]) async throws {
        let orderedIndicesKeyedByIdentifiers = orderedIdentifiers
            .enumerated()
            .reduce(into: [:]) { partialResult, element in
                partialResult[element.element.toAnyHashable()] = element.offset
            }

        cryptoAccountModels
            .sort { first, second in
                guard
                    let firstIndex = orderedIndicesKeyedByIdentifiers[first.id.toAnyHashable()],
                    let secondIndex = orderedIndicesKeyedByIdentifiers[second.id.toAnyHashable()]
                else {
                    // Preserve existing order
                    return false
                }

                return firstIndex < secondIndex
            }
    }

    func dispose() {}
}
