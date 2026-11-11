//
//  CommonNotificationBadgeService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import UIKit
import TangemFoundation

final class CommonNotificationBadgeService {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    private let applier: NotificationBadgeApplier
    private let notificationCenter: NotificationCenter
    private let debounceInterval: DispatchQueue.SchedulerTimeType.Stride

    private var walletsSubscription: AnyCancellable?
    private var repositoryEventsSubscription: AnyCancellable?
    private var isInitialized = false

    init(
        applier: NotificationBadgeApplier = UserNotificationCenterBadgeApplier(),
        notificationCenter: NotificationCenter = .default,
        debounceInterval: DispatchQueue.SchedulerTimeType.Stride = .seconds(1)
    ) {
        self.applier = applier
        self.notificationCenter = notificationCenter
        self.debounceInterval = debounceInterval
    }
}

// MARK: - NotificationBadgeService protocol conformance

extension CommonNotificationBadgeService: NotificationBadgeService {
    func initialize() {
        guard !isInitialized else {
            return
        }

        isInitialized = true
        setup(wallets: userWalletRepository.models)
        bind()
    }
}

// MARK: - Private

private extension CommonNotificationBadgeService {
    func bind() {
        repositoryEventsSubscription = userWalletRepository
            .eventProvider
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { service, event in
                service.handle(event: event)
            }
    }

    func handle(event: UserWalletRepositoryEvent) {
        switch event {
        case .deleted(_, isRepositoryEmpty: true):
            walletsSubscription = nil
            apply(count: 0)
        case .unlocked, .unlockedWallet, .inserted, .deleted:
            setup(wallets: userWalletRepository.models)
        case .selected where walletsSubscription == nil:
            setup(wallets: userWalletRepository.models)
        case .locked:
            walletsSubscription = nil
        case .selected, .reordered:
            break
        }
    }

    func setup(wallets: [UserWalletModel]) {
        guard wallets.isNotEmpty else {
            walletsSubscription = nil
            return
        }

        let countPublisher = CompositeNotificationBadgeCounter(counters: wallets)
            .notificationBadgeCountPublisher
            .debounce(for: debounceInterval, scheduler: DispatchQueue.main)
            .removeDuplicates()

        let appActivationPublisher = notificationCenter
            .publisher(for: UIApplication.didBecomeActiveNotification)
            .map { _ in }
            .prepend(())

        walletsSubscription = Publishers.CombineLatest(appActivationPublisher, countPublisher)
            .map(\.1)
            .withWeakCaptureOf(self)
            .sink { service, count in
                service.apply(count: count)
            }
    }

    func apply(count: Int) {
        NotificationBadgeLogger.info("Applying app icon badge count \(count)")
        runTask(in: self) { service in
            do {
                try await service.applier.apply(count: count)
            } catch {
                NotificationBadgeLogger.error("Failed to apply the app icon badge count", error: error)
            }
        }
    }
}
