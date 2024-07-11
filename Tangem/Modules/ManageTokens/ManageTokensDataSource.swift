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

    private let _userWalletModels: CurrentValueSubject<[UserWalletModel], Never> = .init([])

    var userWalletModels: [UserWalletModel] { _userWalletModels.value }
    var userWalletModelsPublisher: AnyPublisher<[UserWalletModel], Never> { _userWalletModels.eraseToAnyPublisher() }

    var defaultUserWalletModel: UserWalletModel? { userWalletRepository.selectedModel }

    // MARK: - Private Properties

    private var bag = Set<AnyCancellable>()

    // MARK: - Init

    init() {
        let userWalletModels = userWalletRepository.models.filter { !$0.isUserWalletLocked }
        _userWalletModels.send(userWalletModels)
    }
}
