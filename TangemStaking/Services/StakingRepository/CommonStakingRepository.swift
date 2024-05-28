//
//  CommonStakingRepository.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class CommonStakingRepository {
    private let provider: StakingAPIProvider
    private let logger: Logger

    private var updatingTaks: Task<Void, Error>?
    private var availableYields: CurrentValueSubject<[YieldInfo]?, Never> = .init(nil)

    init(provider: StakingAPIProvider, logger: Logger) {
        self.provider = provider
        self.logger = logger
    }
}

extension CommonStakingRepository: StakingRepository {
    var enabledYieldsPuiblisher: AnyPublisher<[YieldInfo], Never> {
        availableYields.compactMap { $0 }.eraseToAnyPublisher()
    }

    func updateEnabledYields(withReload: Bool) {
        if withReload {
            availableYields.value = nil
        }

        guard availableYields.value == nil else {
            return
        }

        updatingTaks?.cancel()
        updatingTaks = Task { [weak self] in
            self?.availableYields.value = try await self?.provider.enabledYields()
        }
    }

    func getYield(id: String) -> YieldInfo? {
        return availableYields.value?.first(where: { $0.id == id })
    }

    func getYield(item: StakingTokenItem) -> YieldInfo? {
        return availableYields.value?.first(where: { $0.item == item })
    }
}
