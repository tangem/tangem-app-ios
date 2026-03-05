//
//  CommonMobileUpgradeBannerManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

final class CommonMobileUpgradeBannerManager: MobileUpgradeBannerManager {
    @Injected(\.mobileUpgradeBannerStorageManager)
    private var storageManager: MobileUpgradeBannerStorageManager

    var shouldShowPublisher: AnyPublisher<Bool, Never> {
        shouldShowSubject
            .compactMap { $0 }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    private let shouldShowSubject = CurrentValueSubject<Bool?, Never>(nil)

    private let walletCreateActivationDays: Int = 30
    private let bannerCloseExpirationDays: Int = 30

    private let userWalletId: UserWalletId

    private var bag: Set<AnyCancellable> = []

    init(userWalletModel: UserWalletModel) {
        userWalletId = userWalletModel.userWalletId

        if canUpgrade(userWalletModel: userWalletModel) {
            setup()
            bind(userWalletModel: userWalletModel)
        } else {
            shouldShow(false)
        }
    }

    func shouldClose() {
        close()
    }
}

// MARK: - Private methods

private extension CommonMobileUpgradeBannerManager {
    func setup() {
        let shouldShow = shouldShow()
        self.shouldShow(shouldShow)
    }

    func shouldShow() -> Bool {
        let topUpDate = storageManager.getWalletTopUpDate(userWalletId: userWalletId)
        if let closeDate = storageManager.getBannerCloseDate(userWalletId: userWalletId) {
            return shouldShowIfClosed(closeDate: closeDate, topUpDate: topUpDate)
        } else {
            return shouldShowIfNeverClosed(topUpDate: topUpDate)
        }
    }

    func shouldShowIfClosed(closeDate: Date, topUpDate: Date?) -> Bool {
        if isBannerCloseExpired(for: closeDate) {
            return true
        } else if let topUpDate {
            return topUpDate > closeDate
        } else {
            return false
        }
    }

    func shouldShowIfNeverClosed(topUpDate: Date?) -> Bool {
        let createDate = storageManager.getWalletCreateDate(userWalletId: userWalletId) ?? Date()
        if isWalletCreateActivated(for: createDate) {
            return true
        } else {
            return topUpDate != nil
        }
    }

    func canUpgrade(userWalletModel: UserWalletModel) -> Bool {
        userWalletModel.config.hasFeature(.userWalletUpgrade)
    }

    func bind(userWalletModel: UserWalletModel) {
        userWalletModel.updatePublisher
            .withWeakCaptureOf(self)
            .sink { manager, updateResult in
                manager.unbindIfNeeded(updateResult: updateResult)
            }
            .store(in: &bag)

        guard hasNoTopUp() else {
            return
        }

        userWalletModel
            .totalBalancePublisher
            .map { $0.hasAnyPositiveBalance }
            .first { $0 }
            .withWeakCaptureOf(self)
            .sink { manager, _ in
                manager.handleTopUp()
            }
            .store(in: &bag)
    }

    func hasNoTopUp() -> Bool {
        storageManager.getWalletTopUpDate(userWalletId: userWalletId) == nil
    }

    func unbindIfNeeded(updateResult: UpdateResult) {
        guard case .configurationChanged(let userWalletModel) = updateResult else {
            return
        }

        guard canUpgrade(userWalletModel: userWalletModel) else {
            shouldShow(false)
            unbind()
            return
        }
    }

    func handleTopUp() {
        if hasNoTopUp() {
            saveWalletTopUp(date: Date())
        }
    }

    func shouldShow(_ value: Bool) {
        shouldShowSubject.send(value)
    }

    func close() {
        storageManager.store(userWalletId: userWalletId, bannerCloseDate: Date())
        shouldShow(false)
    }

    func unbind() {
        bag.removeAll()
    }
}

// MARK: - Helpers

private extension CommonMobileUpgradeBannerManager {
    func saveWalletTopUp(date: Date) {
        storageManager.store(userWalletId: userWalletId, walletTopUpDate: date)
    }

    func isBannerCloseExpired(for date: Date) -> Bool {
        daysPassed(from: date) >= bannerCloseExpirationDays
    }

    func isWalletCreateActivated(for date: Date) -> Bool {
        daysPassed(from: date) >= walletCreateActivationDays
    }

    func daysPassed(from date: Date) -> Int {
        Calendar.current
            .dateComponents([.day], from: date, to: Date())
            .day ?? 0
    }
}
