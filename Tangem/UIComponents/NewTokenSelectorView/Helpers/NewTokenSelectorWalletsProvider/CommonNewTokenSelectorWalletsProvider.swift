//
//  CommonNewTokenSelectorWalletsProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine

class CommonNewTokenSelectorWalletsProvider: NewTokenSelectorWalletsProvider {
    @Injected(\.userWalletRepository)
    private var userWalletRepository: UserWalletRepository

    private let availabilityProviderFactory: any NewTokenSelectorItemAvailabilityProviderFactory

    init(availabilityProviderFactory: any NewTokenSelectorItemAvailabilityProviderFactory) {
        self.availabilityProviderFactory = availabilityProviderFactory
    }

    var wallets: [NewTokenSelectorWallet] {
        userWalletRepository.models.map { userWalletModel in
            mapToNewTokenSelectorWallet(userWalletModel: userWalletModel)
        }
    }

    var walletsPublisher: AnyPublisher<[NewTokenSelectorWallet], Never> {
        Just(userWalletRepository.models)
            .withWeakCaptureOf(self)
            .map { provider, userWalletModels in
                userWalletModels.map { userWalletModel in
                    provider.mapToNewTokenSelectorWallet(userWalletModel: userWalletModel)
                }
            }
            .eraseToAnyPublisher()
    }

    // MARK: - Mapping

    func mapToNewTokenSelectorWallet(userWalletModel: any UserWalletModel) -> NewTokenSelectorWallet {
        let accountsPublisher = userWalletModel.accountModelsManager
            .accountModelsPublisher
            .withWeakCaptureOf(self)
            .compactMap { provider, accountModels -> NewTokenSelectorWallet.AccountType? in
                guard let cryptoAccountModel = accountModels.standard() else {
                    assertionFailure("UserWalletModel does not contain CryptoAccount")
                    return nil
                }

                switch cryptoAccountModel {
                case .standard(.single(let account)):
                    return .single(
                        provider.mapToNewTokenSelectorAccount(wallet: userWalletModel, cryptoAccount: account)
                    )
                case .standard(.multiple(let accounts)):
                    return .multiple(accounts.map {
                        provider.mapToNewTokenSelectorAccount(wallet: userWalletModel, cryptoAccount: $0)
                    })
                }
            }
            .eraseToAnyPublisher()

        return NewTokenSelectorWallet(wallet: userWalletModel.userWalletInfo, accountsPublisher: accountsPublisher)
    }

    func mapToNewTokenSelectorAccount(wallet: any UserWalletModel, cryptoAccount: any CryptoAccountModel) -> NewTokenSelectorAccount {
        let adapter = TokenSectionsAdapter(
            userTokensManager: cryptoAccount.userTokensManager,
            optionsProviding: OrganizeTokensOptionsManager(userTokensReorderer: cryptoAccount.userTokensManager),
            preservesLastSortedOrderOnSwitchToDragAndDrop: false
        )

        let sourcePublisherFactory = TokenSectionsSourcePublisherFactory()
        let tokenSectionsSourcePublisher = sourcePublisherFactory.makeSourcePublisher(for: cryptoAccount, in: wallet)

        let itemsPublisher = adapter
            .organizedSections(from: tokenSectionsSourcePublisher, on: .global())
            .map { section -> [any WalletModel] in
                section.flatMap { $0.items.compactMap { $0.walletModel } }
            }
            .withWeakCaptureOf(self)
            .map { provider, walletModels in
                withExtendedLifetime(adapter) {}

                return walletModels.map { walletModel in
                    provider.mapToNewTokenSelectorItem(
                        userWalletInfo: wallet.userWalletInfo, cryptoAccount: cryptoAccount, walletModel: walletModel
                    )
                }
            }
            .eraseToAnyPublisher()

        return NewTokenSelectorAccount(cryptoAccount: cryptoAccount, itemsPublisher: itemsPublisher)
    }

    func mapToNewTokenSelectorItem(
        userWalletInfo: UserWalletInfo,
        cryptoAccount: any CryptoAccountModel,
        walletModel: any WalletModel
    ) -> NewTokenSelectorItem {
        NewTokenSelectorItem(
            userWalletInfo: userWalletInfo,
            account: cryptoAccount,
            walletModel: walletModel,
            availabilityProvider: availabilityProviderFactory.makeAvailabilityProvider(
                userWalletInfo: userWalletInfo,
                walletModel: walletModel
            ),
        )
    }
}
