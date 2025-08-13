//
//  BalanceRestrictionFeatureAvailabilityProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class BalanceRestrictionFeatureAvailabilityProvider {
    private let userWalletConfig: UserWalletConfig
    private let totalBalanceProvider: TotalBalanceProviding

    private let isSwapAvailableSubject: CurrentValueSubject<Bool, Never>
    private var bag = Set<AnyCancellable>()

    var isSwapAvailablePublisher: AnyPublisher<Bool, Never> {
        isSwapAvailableSubject.eraseToAnyPublisher()
    }

    init(userWalletConfig: UserWalletConfig, totalBalanceProvider: TotalBalanceProviding) {
        self.userWalletConfig = userWalletConfig
        self.totalBalanceProvider = totalBalanceProvider

        let isBalanceRestrictionActive = userWalletConfig.hasFeature(.isBalanceRestrictionActive)

        self.isSwapAvailableSubject = CurrentValueSubject(!isBalanceRestrictionActive)

        if isBalanceRestrictionActive {
            bind()
        }
    }

    private func bind() {
        totalBalanceProvider.totalBalancePublisher
            .map { totalBalanceState in
                switch totalBalanceState {
                case .empty: false
                case .loading(let cached): (cached ?? 0) > 0
                case .failed: false
                case .loaded(let balance): balance > 0
                }
            }
            .sink(receiveValue: { [isSwapAvailableSubject] value in
                isSwapAvailableSubject.send(value)
            })
            .store(in: &bag)
    }
}
