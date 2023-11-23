//
//  ManageTokensDataSource.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class ManageTokensDataSource {
    // MARK: - Injected

    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    var userWalletModelsSubject: CurrentValueSubject<[UserWalletModel], Never> = .init([])

    var defaultUserWalletModel: UserWalletModel? {
        userWalletRepository.selectedUserModelModel
    }

    // MARK: - Private Properties

    private var bag = Set<AnyCancellable>()

    // MARK: - Init

    init() {
        userWalletRepository
            .eventProvider
            .filter { event in
                switch event {
                case .locked, .unlocked, .inserted, .deleted:
                    return true
                default:
                    return false
                }
            }
            .sink { [weak self] event in
                guard let self = self else { return }

                let userWalletModels = userWalletRepository.models.filter { !$0.isUserWalletLocked }
                userWalletModelsSubject.send(userWalletModels)
            }
            .store(in: &bag)
    }
}
