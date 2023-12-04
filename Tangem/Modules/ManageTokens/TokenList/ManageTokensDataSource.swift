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

    var _userWalletModels: CurrentValueSubject<[UserWalletModel], Never> = .init([])
    var userWalletModels: [UserWalletModel] { _userWalletModels.value }

    var defaultUserWalletModel: UserWalletModel? { userWalletRepository.selectedModel }

    // MARK: - Private Properties

    private var bag = Set<AnyCancellable>()

    // MARK: - Init

    init() {
        userWalletRepository
            .eventProvider
            .filter { event in
                switch event {
                case .locked, .inserted, .deleted, .biometryUnlocked:
                    return true
                default:
                    return false
                }
            }
            .sink { [weak self] event in
                guard let self = self else { return }

                let userWalletModels = userWalletRepository.models.filter { !$0.isUserWalletLocked }
                _userWalletModels.send(userWalletModels)
            }
            .store(in: &bag)
    }
}
