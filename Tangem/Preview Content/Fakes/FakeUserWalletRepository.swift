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
    var savedWallets: [LockedUserWalletModel]? { nil }

    var selectedUserWalletId: UserWalletId?

    var isLocked: Bool { false }

    var hasSavedWallets: Bool { true }

    var models: [UserWalletModel] = []

    var selectedModel: UserWalletModel?

    var selectedIndexUserWalletModel: Int?

    var eventProvider: AnyPublisher<UserWalletRepositoryEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    private let eventSubject = PassthroughSubject<UserWalletRepositoryEvent, Never>()

    init(models: [UserWalletModel] = FakeUserWalletModel.allFakeWalletModels) {
        self.models = models
    }

    func unlock(with method: UserWalletRepositoryUnlockMethod, completion: @escaping (UserWalletRepositoryResult?) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            guard self.models.first != nil else {
                completion(.error("No models"))
                return
            }

            switch method {
            case .biometry:
                completion(.troubleshooting)
            case .card(let userWalletId, _):
                if let userWalletId, let userWalletModel = self.models.first(where: { $0.userWalletId == userWalletId }) {
                    completion(.success(userWalletModel))
                    return
                }

                completion(.error("Can't create card view model"))
            case .passcode:
                completion(.troubleshooting)
            }
        }
    }

    func setSelectedUserWalletId(_ userWalletId: UserWalletId, reason: UserWalletRepositorySelectionChangeReason) {}

    func updateSelection() {}

    func lock() {}

    func add(_ userWalletModel: UserWalletModel) {}

    func addOrScan(scanner: CardScanner, completion: @escaping (UserWalletRepositoryResult?) -> Void) {}

    func delete(_ userWalletId: UserWalletId) {}

    func clearNonSelectedUserWallets() {}

    func initialize() {}

    func initializeServices(for userWalletModel: UserWalletModel) {}

    func initialClean() {}

    func setSaving(_ enabled: Bool) {}

    func save() {}

    func changePassword(old: String?, new: String, for userWalletId: UserWalletId) throws {}
}
