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
    private let userTokensManager: UserTokensManager
    private let userTokenListManager: UserTokenListManager
    private let accountModelsSubject = CurrentValueSubject<[AccountModel], Never>([])
    private let totalAccountsCountSubject = CurrentValueSubject<Int, Never>(0)

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
        userTokensManager: UserTokensManager = UserTokensManagerMock(),
        userTokenListManager: UserTokenListManager = UserTokenListManagerMock()
    ) {
        self.walletModelsManager = walletModelsManager
        self.userTokensManager = userTokensManager
        self.userTokenListManager = userTokenListManager

        // `defer` is used to trigger the `didSet` observer
        defer {
            let mainAccount = CryptoAccountModelMock(
                isMainAccount: true,
                walletModelsManager: walletModelsManager,
                userTokensManager: userTokensManager,
                userTokenListManager: userTokenListManager
            )

            let secondAccount = CryptoAccountModelMock(
                isMainAccount: false,
                walletModelsManager: walletModelsManager,
                userTokensManager: userTokensManager,
                userTokenListManager: userTokenListManager
            )

            cryptoAccountModels = [mainAccount, secondAccount]
        }
    }

    private func removeCryptoAccount(withIdentifier identifier: AnyHashable) {
        cryptoAccountModels.removeAll { $0.id.toPersistentIdentifier().toAnyHashable() == identifier }
    }
}

// MARK: - AccountModelsManager protocol conformance

extension AccountModelsManagerMock: AccountModelsManager {
    var canAddCryptoAccounts: Bool {
        true
    }

    var hasArchivedCryptoAccounts: AnyPublisher<Bool, Never> {
        .just(output: false)
    }

    var totalAccountsCountPublisher: AnyPublisher<Int, Never> {
        totalAccountsCountSubject.eraseToAnyPublisher()
    }

    var accountModelsPublisher: AnyPublisher<[AccountModel], Never> {
        accountModelsSubject.eraseToAnyPublisher()
    }

    func addCryptoAccount(name: String, icon: AccountModel.Icon) async throws(AccountModelsManagerError) {
        cryptoAccountModels.append(CryptoAccountModelMock(isMainAccount: false, walletModelsManager: walletModelsManager))
    }

    func archivedCryptoAccountInfos() async throws(AccountModelsManagerError) -> [ArchivedCryptoAccountInfo] {
        // [REDACTED_TODO_COMMENT]
        return []
    }

    func archiveCryptoAccount(
        withIdentifier identifier: any AccountModelPersistentIdentifierConvertible
    ) throws(AccountModelsManagerError) {
        removeCryptoAccount(withIdentifier: identifier.toPersistentIdentifier().toAnyHashable())
    }

    func unarchiveCryptoAccount(info: ArchivedCryptoAccountInfo) throws(AccountModelsManagerError) {
        // [REDACTED_TODO_COMMENT]
        throw .cannotUnarchiveCryptoAccount
    }
}
