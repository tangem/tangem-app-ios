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
    var hasSavedWallets: Bool { true }

    var models: [UserWalletModel] = []

    var userWallets: [StoredUserWallet] = []

    var selectedModel: UserWalletModel?

    var selectedUserWalletId: Data?

    var selectedIndexUserWalletModel: Int?

    var isEmpty: Bool { models.isEmpty }

    var count: Int { models.count }

    var isLocked: Bool = false

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
            case .card(let userWallet):
                if let userWallet, let userWalletModel = CommonUserWalletModel(userWallet: userWallet) {
                    completion(.success(userWalletModel))
                    return
                }

                completion(.error("Can't create card view model"))
            }
        }
    }

    func setSelectedUserWalletId(_ userWalletId: Data?, unlockIfNeeded: Bool, reason: UserWalletRepositorySelectionChangeReason) {}

    func updateSelection() {}

    func logoutIfNeeded() {}

    func add(_ userWalletModel: UserWalletModel) {}

    func add(_ completion: @escaping (UserWalletRepositoryResult?) -> Void) {}

    func addOrScan(completion: @escaping (UserWalletRepositoryResult?) -> Void) {}

    func save(_ userWalletModel: UserWalletModel) {}

    func contains(_ userWallet: StoredUserWallet) -> Bool {
        return false
    }

    func save(_ userWallet: StoredUserWallet) {}

    func delete(_ userWalletId: UserWalletId, logoutIfNeeded shouldAutoLogout: Bool) {}

    func clearNonSelectedUserWallets() {}

    func initialize() {}

    func initializeServices(for userWalletModel: UserWalletModel) {}

    func initialClean() {}

    func setSaving(_ enabled: Bool) {}
}
