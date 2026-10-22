//
//  TangemPayDepositOwnersPublisherFactory.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import CombineExt
import TangemFoundation
import TangemPay

enum TangemPayDepositOwnersPublisherFactory {
    static func makePublisher(userWalletRepository: UserWalletRepository) -> some Publisher<[TangemPayDepositOwner], Never> {
        userWalletRepository.eventProvider
            .mapToVoid()
            .prepend(())
            .map { userWalletRepository.models }
            .flatMapLatest { userWalletModels in
                userWalletModels
                    .map(depositNetworksPublisher(of:))
                    .merge()
                    .mapToVoid()
                    .prepend(())
                    .map { userWalletModels }
            }
            .receiveOnMain()
            .map { TangemPayDepositOwner.make(from: $0) }
            .removeDuplicates()
    }

    private static func depositNetworksPublisher(of userWalletModel: UserWalletModel) -> some Publisher<[TangemPayBalance.Network], Never> {
        AccountModelsAggregator(.tangemPay)
            .modelPublisher(from: userWalletModel.accountModelsManager)
            .flatMapLatest { accountModel -> AnyPublisher<[TangemPayBalance.Network], Never> in
                guard let accountModel else {
                    return .just(output: [])
                }

                return accountModel.statePublisher
                    .flatMapLatest { _ -> AnyPublisher<[TangemPayBalance.Network], Never> in
                        guard let account = accountModel.state?.tangemPayAccount ?? accountModel.lastKnownTangemPayAccount else {
                            return .just(output: [])
                        }

                        return account.balancesProvider.totalTokenBalanceProvider.balanceTypePublisher
                            .map { _ in account.networks }
                            .eraseToAnyPublisher()
                    }
                    .eraseToAnyPublisher()
            }
            .removeDuplicates()
    }
}
