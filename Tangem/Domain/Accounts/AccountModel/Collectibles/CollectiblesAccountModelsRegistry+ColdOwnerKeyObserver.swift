//
//  CollectiblesAccountModelsRegistry+ColdOwnerKeyObserver.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import CombineExt

extension CollectiblesAccountModelsRegistry {
    struct ColdOwnerKeyObserver {
        private let subscription: AnyCancellable

        init(
            keysPublisher: AnyPublisher<[KeyInfo], Never>,
            isSyncRequiredPublisher: AnyPublisher<Bool, Never>,
            isOnboardingPublisher: AnyPublisher<Bool, Never>,
            refreshState: @escaping () -> Void
        ) {
            subscription = keysPublisher
                .dropFirst()
                .withLatestFrom(isSyncRequiredPublisher, isOnboardingPublisher)
                .filter { isSyncRequired, isOnboarding in isSyncRequired && !isOnboarding }
                .sink { _ in
                    refreshState()
                }
        }
    }
}
