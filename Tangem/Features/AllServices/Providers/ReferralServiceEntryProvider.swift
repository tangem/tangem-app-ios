//
//  ReferralServiceEntryProvider.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation

final class ReferralServiceEntryProvider {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    var isAvailablePublisher: AnyPublisher<Bool, Never> {
        userWalletRepository
            .eventProvider
            .filter { event in
                switch event {
                case .locked, .unlocked, .inserted, .unlockedWallet, .deleted: true
                case .selected, .reordered: false
                }
            }
            .mapToVoid()
            .prepend(())
            .withWeakCaptureOf(self)
            .map { provider, _ in !provider.wallets.isEmpty }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    var wallets: [UserWalletModel] {
        UserWalletModelsProvider
            .available(from: userWalletRepository.models)
            .filter { $0.config.hasFeature(.referralProgram) }
    }
}
