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
            .filter {
                if case .unlocked = $0 {
                    return true
                }

                return false
            }
            .sink { [weak self] _ in
                guard let self = self else { return }

                let userWalletModels = userWalletRepository.models.filter { !$0.isUserWalletLocked }
                userWalletModelsSubject.send(userWalletModels)
            }
            .store(in: &bag)
    }
}
