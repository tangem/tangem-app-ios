//
//  AccountsAwareNFTManagerProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemNFT

final class CommonAccountsAwareNFTManagersFacade {
    private let plainNFTManagerDummyAccountID = "plain_nft_manager_dummy_account_id"
    private let workMode: WorkMode

    private var nftMangersWithAccountsInfoSubject: CurrentValueSubject<AccountsWithNFTManagersState?, Never> = .init(nil)
    private var bag = Set<AnyCancellable>()

    init(workMode: WorkMode) {
        self.workMode = workMode
        bind()
    }

    func bind() {
        switch workMode {
        case .accounts(let accountsManager):
            bindAccountsManager(accountsManager)

        case .plainNFTManager(let nftManager):
            nftMangersWithAccountsInfoSubject.send(
                AccountsWithNFTManagersState.singleAccount(
                    accountID: plainNFTManagerDummyAccountID,
                    nftManager
                )
            )
        }
    }

    private func bindAccountsManager(_ accountsManager: AccountModelsManager) {
        accountsManager.accountModelsPublisher
            .withWeakCaptureOf(self)
            .compactMap { provider, accountModels in
                accountModels
                    .compactMap {
                        switch $0 {
                        case .standard(let cryptoAccounts):
                            return provider.mapCryptoAccount(cryptoAccounts)
                        }
                    }
                    .first
            }
            .withWeakCaptureOf(self)
            .sink { provider, state in
                provider.nftMangersWithAccountsInfoSubject.send(state)
            }
            .store(in: &bag)
    }

    private func mapCryptoAccount(_ accs: CryptoAccounts) -> AccountsWithNFTManagersState? {
        switch accs {
        case .single(let cryptoAccountModel):
            return .singleAccount(accountID: cryptoAccountModel.id, cryptoAccountModel.nftManager)

        case .multiple(let cryptoAccountModels):
            return .multipleAccounts(
                cryptoAccountModels.map {
                    AccountsWithNFTManagersData(accountID: $0.id, nftManager: $0.nftManager)
                })
        }
    }

    private var currentState: AccountsWithNFTManagersState? {
        nftMangersWithAccountsInfoSubject.value
    }
}

extension CommonAccountsAwareNFTManagersFacade: AccountsAwareNFTManagersFacade {
    var collectionsPublisher: AnyPublisher<NFTPartialResult<[NFTCollection]>, Never> {
        let publishers = currentState?.nftManagers.map(\.collectionsPublisher) ?? []

        return Publishers.MergeMany(publishers)
            .eraseToAnyPublisher()
    }

    var collections: [NFTCollection] {
        currentState
            .map {
                $0.nftManagers.flatMap(\.collections)
            } ?? []
    }

    var primaryNFTManager: any NFTManager {
        currentState?.nftManagers.first ?? NFTManagerStub()
    }

    func updateInternal() {
        currentState
            .map {
                switch $0 {
                case .singleAccount(_, let nftManager):
                    nftManager.update(cachePolicy: .always)

                case .multipleAccounts(let accountsData):
                    accountsData.forEach { $0.nftManager.update(cachePolicy: .always) }
                }
            }
    }
}

extension CommonAccountsAwareNFTManagersFacade {
    enum WorkMode {
        case accounts(AccountModelsManager)
        case plainNFTManager(NFTManager)
    }
}
