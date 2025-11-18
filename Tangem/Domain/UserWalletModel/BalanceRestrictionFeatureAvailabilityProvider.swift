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

    private let isActionButtonsAvailableSubject: CurrentValueSubject<Bool, Never>
    private var bag = Set<AnyCancellable>()

    var isActionButtonsAvailablePublisher: AnyPublisher<Bool, Never> {
        isActionButtonsAvailableSubject.eraseToAnyPublisher()
    }

    var isActionButtonsAvailable: Bool {
        isActionButtonsAvailableSubject.value
    }

    init(userWalletConfig: UserWalletConfig, totalBalanceProvider: TotalBalanceProviding) {
        self.userWalletConfig = userWalletConfig
        self.totalBalanceProvider = totalBalanceProvider

        let isBalanceRestrictionActive = userWalletConfig.hasFeature(.isBalanceRestrictionActive)

        isActionButtonsAvailableSubject = CurrentValueSubject(!isBalanceRestrictionActive)

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
                case .failed(let cached, _): (cached ?? 0) > 0
                case .loaded(let balance): balance > 0
                }
            }
            .sink(receiveValue: { [isActionButtonsAvailableSubject] value in
                isActionButtonsAvailableSubject.send(value)
            })
            .store(in: &bag)
    }
}
