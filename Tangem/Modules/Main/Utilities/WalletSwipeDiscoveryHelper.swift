//
//  WalletSwipeDiscoveryHelper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

protocol WalletSwipeDiscoveryHelperDelegate: AnyObject {
    func numberOfWallets(_ discoveryHelper: WalletSwipeDiscoveryHelper) -> Int
    func userDidSwipeWallets(_ discoveryHelper: WalletSwipeDiscoveryHelper) -> Bool
    func helperDidTriggerSwipeDiscoveryAnimation(_ discoveryHelper: WalletSwipeDiscoveryHelper)
}

final class WalletSwipeDiscoveryHelper {
    weak var delegate: WalletSwipeDiscoveryHelperDelegate?

    private var scheduledSwipeDiscovery: DispatchWorkItem?
    private var lastNumberOfWallets = Constants.lastNumberOfWallets

    func scheduleSwipeDiscoveryIfNeeded() {
        cancelScheduledSwipeDiscovery()

        let workItem = DispatchWorkItem { [weak self] in
            guard
                let self = self,
                canTriggerSwipeDiscovery()
            else {
                return
            }

            delegate?.helperDidTriggerSwipeDiscoveryAnimation(self)
        }

        scheduledSwipeDiscovery = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.discoveryAnimationDelay, execute: workItem)
    }

    func cancelScheduledSwipeDiscovery() {
        scheduledSwipeDiscovery?.cancel()
    }

    private func canTriggerSwipeDiscovery() -> Bool {
        guard let delegate = delegate else { return false }

        let numberOfWallets = delegate.numberOfWallets(self)

        defer { lastNumberOfWallets = numberOfWallets }

        // The discovery is triggered only if there is more than one wallet and the number
        // of wallets is increased since the last attempt to trigger swipe discovery
        guard
            numberOfWallets > 1,
            numberOfWallets > lastNumberOfWallets
        else {
            return false
        }

        return !delegate.userDidSwipeWallets(self)
    }

    func reset() {
        lastNumberOfWallets = delegate?.numberOfWallets(self) ?? Constants.lastNumberOfWallets
    }
}

// MARK: - Constants

private extension WalletSwipeDiscoveryHelper {
    enum Constants {
        static let discoveryAnimationDelay = 1.0
        static let lastNumberOfWallets = 0
    }
}
