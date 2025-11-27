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
    var isActionButtonsAvailablePublisher: AnyPublisher<Bool, Never> {
        isActionButtonsAvailableSubject.eraseToAnyPublisher()
    }

    var isActionButtonsAvailable: Bool {
        isActionButtonsAvailableSubject.value
    }

    private let isBalanceRestrictionActiveSubject: CurrentValueSubject<Bool, Never>
    private let isActionButtonsAvailableSubject: CurrentValueSubject<Bool, Never>

    private var bag = Set<AnyCancellable>()

    init(
        userWalletConfig: UserWalletConfig,
        walletModelsPublisher: AnyPublisher<[any WalletModel], Never>,
        updatePublisher: AnyPublisher<UpdateResult, Never>
    ) {
        let isBalanceRestrictionActive = userWalletConfig.hasFeature(.isBalanceRestrictionActive)
        isBalanceRestrictionActiveSubject = CurrentValueSubject(isBalanceRestrictionActive)
        isActionButtonsAvailableSubject = CurrentValueSubject(!isBalanceRestrictionActive)

        bind(walletModelsPublisher: walletModelsPublisher, updatePublisher: updatePublisher)
    }

    private func bind(
        walletModelsPublisher: AnyPublisher<[any WalletModel], Never>,
        updatePublisher: AnyPublisher<UpdateResult, Never>
    ) {
        let totalBalancesPublisher: AnyPublisher<[TokenBalanceType], Never> = walletModelsPublisher
            .map { walletModels in
                guard !walletModels.isEmpty else {
                    return Just([TokenBalanceType]()).eraseToAnyPublisher()
                }
                return walletModels
                    .map { $0.availableBalanceProvider.balanceTypePublisher }
                    .combineLatest()
            }
            .switchToLatest()
            .eraseToAnyPublisher()

        isBalanceRestrictionActiveSubject
            .combineLatest(totalBalancesPublisher)
            .map { isBalanceRestrictionActive, totalBalances in
                if isBalanceRestrictionActive {
                    return totalBalances.compactMap { $0.value }.contains(where: { $0 > 0 })
                } else {
                    return true
                }
            }
            .removeDuplicates()
            .subscribe(isActionButtonsAvailableSubject)
            .store(in: &bag)

        updatePublisher
            .compactMap { update in
                switch update {
                case .configurationChanged(let userWalletModel):
                    return userWalletModel.config.hasFeature(.isBalanceRestrictionActive)
                default:
                    return nil
                }
            }
            .subscribe(isBalanceRestrictionActiveSubject)
            .store(in: &bag)
    }
}
