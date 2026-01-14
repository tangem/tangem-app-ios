//
//  CommonNFTAvailabilityProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt
import TangemFoundation

final class CommonNFTAvailabilityProvider {
    private let appSettings: AppSettings
    private let userWalletIdsWithNFTEnabled: CurrentValueSubject<Set<String>, Never>

    init(appSettings: AppSettings) {
        self.appSettings = appSettings
        userWalletIdsWithNFTEnabled = .init([])
    }
}

extension CommonNFTAvailabilityProvider: NFTAvailabilityProvider {
    var didChangeNFTAvailabilityPublisher: AnyPublisher<Void, Never> {
        appSettings
            .$userWalletIdsWithNFTEnabled
            .map { $0.toSet() }
            .combineLatest(userWalletIdsWithNFTEnabled) { $0.union($1) }
            .removeDuplicates()
            .mapToVoid()
            .eraseToAnyPublisher()
    }

    func isNFTAvailable(for userWalletConfig: UserWalletConfig) -> Bool {
        ensureOnMainQueue()
        return userWalletConfig.hasFeature(.nft)
    }

    func isNFTEnabled(forUserWalletWithId userWalletId: UserWalletId) -> Bool {
        ensureOnMainQueue()

        let userWalletIdString = userWalletId.stringValue

        return userWalletIdsWithNFTEnabled.value.contains(userWalletIdString)
            || appSettings.userWalletIdsWithNFTEnabled.contains(userWalletIdString)
    }

    func setNFTEnabled(_ enabled: Bool, forUserWalletWithId userWalletId: UserWalletId) {
        ensureOnMainQueue()

        let userWalletIdString = userWalletId.stringValue

        guard isNFTEnabled(forUserWalletWithId: userWalletId) != enabled else {
            return
        }

        if enabled {
            userWalletIdsWithNFTEnabled.value.insert(userWalletIdString)
            appSettings.userWalletIdsWithNFTEnabled.append(userWalletIdString)
        } else {
            userWalletIdsWithNFTEnabled.value.remove(userWalletIdString)
            appSettings.userWalletIdsWithNFTEnabled.remove(userWalletIdString)
        }

        let enabledParameter = enabled ? Analytics.ParameterValue.on : .off
        Analytics.log(.nftToggleSwitch, params: [.status: enabledParameter])
    }
}
