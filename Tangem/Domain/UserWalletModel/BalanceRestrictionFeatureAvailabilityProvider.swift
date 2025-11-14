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
        totalBalanceProvider: TotalBalanceProvider,
        updatePublisher: AnyPublisher<UpdateResult, Never>
    ) {
        let isBalanceRestrictionActive = userWalletConfig.hasFeature(.isBalanceRestrictionActive)
        isBalanceRestrictionActiveSubject = CurrentValueSubject(isBalanceRestrictionActive)
        isActionButtonsAvailableSubject = CurrentValueSubject(!isBalanceRestrictionActive)

        bind(
            totalBalancePublisher: totalBalanceProvider.totalBalancePublisher,
            updatePublisher: updatePublisher
        )
    }

    private func bind(
        totalBalancePublisher: AnyPublisher<TotalBalanceState, Never>,
        updatePublisher: AnyPublisher<UpdateResult, Never>
    ) {
        isBalanceRestrictionActiveSubject
            .combineLatest(totalBalancePublisher)
            .map { isBalanceRestrictionActive, totalBalanceState in
                if isBalanceRestrictionActive {
                    let isActionButtonsAvailable = switch totalBalanceState {
                    case .empty: false
                    case .loading(let cached): (cached ?? 0) > 0
                    case .failed(let cached, _): (cached ?? 0) > 0
                    case .loaded(let balance): balance > 0
                    }
                    return isActionButtonsAvailable
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
