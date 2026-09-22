//
//  UserWalletRepository+SelectedUnlockedModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import CombineExt

extension UserWalletRepository {
    var selectedUnlockedModelPublisher: AnyPublisher<UserWalletModel?, Never> {
        eventProvider
            .mapToVoid()
            .prepend(())
            .map { [self] in selectedModel.flatMap { $0.isUserWalletLocked ? nil : $0 } }
            .removeDuplicates { $0 === $1 }
            .flatMapLatest { wallet -> AnyPublisher<UserWalletModel?, Never> in
                guard let wallet else {
                    return .just(output: nil)
                }

                return wallet.updatePublisher
                    .filter { update in
                        guard case .configurationChanged = update else { return false }
                        return true
                    }
                    .map { _ -> UserWalletModel? in wallet }
                    .prepend(wallet)
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
}
