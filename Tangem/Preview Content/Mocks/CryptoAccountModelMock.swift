//
//  CryptoAccountModelMock.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class CryptoAccountModelMock {
    let id = AccountId()
    let isMainAccount: Bool
    let walletModelsManager: WalletModelsManager = WalletModelsManagerMock()
    let userTokensManager: UserTokensManager = UserTokensManagerMock()
    let userTokenListManager: UserTokenListManager = UserTokenListManagerMock()

    private(set) var name = "Mock Account" {
        didSet {
            if oldValue != name {
                didChangeSubject.send()
            }
        }
    }

    private(set) var icon = AccountModel.Icon(
        nameMode: .named(AccountModel.Icon.Name.allCases.randomElement()!),
        color: .allCases.randomElement()!
    ) {
        didSet {
            if oldValue != icon {
                didChangeSubject.send()
            }
        }
    }

    private let didChangeSubject = PassthroughSubject<Void, Never>()

    init(isMainAccount: Bool) {
        self.isMainAccount = isMainAccount
    }
}

// MARK: - Auxiliary types

extension CryptoAccountModelMock {
    struct AccountId: Hashable, AccountModelPersistentIdentifierConvertible {
        let id = UUID()

        var isMainAccount: Bool {
            false
        }

        func toPersistentIdentifier() -> UUID {
            id
        }
    }
}

// MARK: - CryptoAccountModel protocol conformance

extension CryptoAccountModelMock: CryptoAccountModel {
    var didChangePublisher: AnyPublisher<Void, Never> {
        didChangeSubject.eraseToAnyPublisher()
    }

    func setName(_ name: String) async throws {
        self.name = name
    }

    func setIcon(_ icon: AccountModel.Icon) async throws {
        self.icon = icon
    }
}

// MARK: - WalletModelBalancesProvider protocol conformance

extension CryptoAccountModelMock: WalletModelBalancesProvider {
    var availableBalanceProvider: TokenBalanceProvider {
        NotSupportedStakingTokenBalanceProvider()
    }

    var stakingBalanceProvider: TokenBalanceProvider {
        NotSupportedStakingTokenBalanceProvider()
    }

    var totalTokenBalanceProvider: TokenBalanceProvider {
        NotSupportedStakingTokenBalanceProvider()
    }

    var fiatAvailableBalanceProvider: TokenBalanceProvider {
        NotSupportedStakingTokenBalanceProvider()
    }

    var fiatStakingBalanceProvider: TokenBalanceProvider {
        NotSupportedStakingTokenBalanceProvider()
    }

    var fiatTotalTokenBalanceProvider: TokenBalanceProvider {
        NotSupportedStakingTokenBalanceProvider()
    }
}
