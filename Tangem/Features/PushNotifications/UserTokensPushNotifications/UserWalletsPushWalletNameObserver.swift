//
//  UserWalletsPushWalletNameObserver.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import Combine

final class UserWalletsPushWalletNameObserver {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    private let walletNameUpdater: UserWalletsPushWalletNameUpdating
    private var bag: Set<AnyCancellable> = []

    init(walletNameUpdater: UserWalletsPushWalletNameUpdating = UserWalletsPushWalletNameUpdater()) {
        self.walletNameUpdater = walletNameUpdater
    }

    @MainActor
    func restartObserving() {
        bag.removeAll()

        userWalletRepository.models.map { userWalletModel in
            userWalletModel.updatePublisher
                .compactMap(\.newName)
                .map { (id: userWalletModel.userWalletId.stringValue, name: $0) }
        }
        .merge()
        .sink { [walletNameUpdater] result in
            runTask {
                await walletNameUpdater.updateWalletName(name: result.name, userWalletId: result.id)
            }
        }
        .store(in: &bag)
    }
}
