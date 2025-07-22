//
//  FakeUserWalletRepository.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk

class FakeUserWalletRepository: UserWalletRepository {
    var selectedUserWalletId: UserWalletId?

    var isLocked: Bool { false }

    var models: [UserWalletModel] = []

    var selectedModel: UserWalletModel?

    var eventProvider: AnyPublisher<UserWalletRepositoryEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    private let eventSubject = PassthroughSubject<UserWalletRepositoryEvent, Never>()

    init(models: [UserWalletModel] = FakeUserWalletModel.allFakeWalletModels) {
        self.models = models
    }

    func unlock(with method: UserWalletRepositoryUnlockMethod) throws -> UserWalletModel {
        guard let firstModel = models.first else {
            throw UserWalletRepositoryError.cantUnlockWithCard
        }

        return firstModel
    }

    func unlock(userWalletId: UserWalletId, method: UserWalletRepositoryUnlockMethod) throws {}
    func select(userWalletId: UserWalletId) {}
    func updateSelection() {}
    func lock() {}
    func add(userWalletModel: UserWalletModel) {}
    func delete(userWalletId: UserWalletId) {}
    func save() {}
    func initialize() async {}
    func updateAssociatedCard(userWalletId: UserWalletId, cardId: String) {}
    func savePublicData() {}
    func save(userWalletModel: any UserWalletModel) {}
    func onSaveUserWalletsChanged(enabled: Bool) {}
}
