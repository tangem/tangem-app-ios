//
//  MainNotificationsViewModelTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import Testing
@testable import Tangem

@Suite("Main notifications hide-while-system", .serialized)
@MainActor
struct MainNotificationsViewModelTests {
    @Test("Hides marketing and strips the promo while a system card is present, keeping system banners")
    func hidesWhileSystemPresent() async {
        await withControllableAddFunds { _ in
            let systemInputs = sampleInputs(count: 1)
            let promoInputs = sampleInputs(count: 2)
            let viewModel = makeViewModel(systemInputs: systemInputs, promoInputs: promoInputs)
            let allowedVisibility = PassthroughSubject<MainPromotionalVisibility, Never>()

            viewModel.bindVisibility(
                allowedVisibilityPublisher: allowedVisibility.eraseToAnyPublisher(),
                balanceProvider: TotalBalanceProviderMock()
            )

            allowedVisibility.send(.hidden)

            let hidden = await waitUntilConditionMet(timeout: 4) {
                !hasMarketing(viewModel) && bannerCount(viewModel) == systemInputs.count
            }
            #expect(hidden)
        }
    }

    @Test("Shows marketing and the promo again once the open-check resolves without a system card")
    func showsWhenNoSystemCard() async {
        await withControllableAddFunds { addFunds in
            let systemInputs = sampleInputs(count: 1)
            let promoInputs = sampleInputs(count: 2)
            let viewModel = makeViewModel(systemInputs: systemInputs, promoInputs: promoInputs)
            let allowedVisibility = PassthroughSubject<MainPromotionalVisibility, Never>()

            viewModel.bindVisibility(
                allowedVisibilityPublisher: allowedVisibility.eraseToAnyPublisher(),
                balanceProvider: TotalBalanceProviderMock()
            )

            allowedVisibility.send(.all)
            addFunds.send(false)

            let shown = await waitUntilConditionMet(timeout: 4) {
                hasMarketing(viewModel) && bannerCount(viewModel) == systemInputs.count + promoInputs.count
            }
            #expect(shown)
        }
    }

    @Test("Shows only the promo while Get your first crypto is the only system card, without marketing flashing on open")
    func showsOnlyPromoWithAddFunds() async {
        await withControllableAddFunds { addFunds in
            let systemInputs = sampleInputs(count: 1)
            let promoInputs = sampleInputs(count: 2)
            let viewModel = makeViewModel(systemInputs: systemInputs, promoInputs: promoInputs)
            let allowedVisibility = PassthroughSubject<MainPromotionalVisibility, Never>()

            viewModel.bindVisibility(
                allowedVisibilityPublisher: allowedVisibility.eraseToAnyPublisher(),
                balanceProvider: TotalBalanceProviderMock()
            )

            allowedVisibility.send(.all)
            addFunds.send(true)
            allowedVisibility.send(.tangemPayPromoOnly)

            let shown = await waitUntilConditionMet(timeout: 4) {
                bannerCount(viewModel) == systemInputs.count + promoInputs.count
            }
            #expect(shown)
            #expect(!hasMarketing(viewModel))
        }
    }

    @Test("Hides the promo at once when another system card joins Get your first crypto")
    func hidesPromoWhenAnotherSystemCardAppears() async {
        await withControllableAddFunds { addFunds in
            let systemInputs = sampleInputs(count: 1)
            let promoInputs = sampleInputs(count: 2)
            let viewModel = makeViewModel(systemInputs: systemInputs, promoInputs: promoInputs)
            let allowedVisibility = PassthroughSubject<MainPromotionalVisibility, Never>()

            viewModel.bindVisibility(
                allowedVisibilityPublisher: allowedVisibility.eraseToAnyPublisher(),
                balanceProvider: TotalBalanceProviderMock()
            )

            allowedVisibility.send(.tangemPayPromoOnly)
            addFunds.send(true)

            let promoShown = await waitUntilConditionMet(timeout: 4) {
                bannerCount(viewModel) == systemInputs.count + promoInputs.count
            }
            #expect(promoShown)

            allowedVisibility.send(.hidden)

            let hidden = await waitUntilConditionMet(timeout: 4) {
                !hasMarketing(viewModel) && bannerCount(viewModel) == systemInputs.count
            }
            #expect(hidden)
        }
    }
}

// MARK: - Helpers

private extension MainNotificationsViewModelTests {
    func makeViewModel(
        systemInputs: [NotificationViewInput],
        promoInputs: [NotificationViewInput]
    ) -> MainNotificationsViewModel {
        MainNotificationsViewModel(
            promotionNotificationsManager: FakePromotionNotificationsManager(),
            systemBannerItemsProvider: NotificationBannerItemsProvider(managers: [StubNotificationManager(inputs: systemInputs)]),
            tangemPayPromoManager: StubNotificationManager(inputs: promoInputs)
        )
    }

    func sampleInputs(count: Int) -> [NotificationViewInput] {
        Array(FakePromotionNotificationsManager().notificationInputs.prefix(count))
    }

    func hasMarketing(_ viewModel: MainNotificationsViewModel) -> Bool {
        viewModel.sections.contains {
            if case .marketing = $0 { return true }
            return false
        }
    }

    func bannerCount(_ viewModel: MainNotificationsViewModel) -> Int {
        for section in viewModel.sections {
            if case .systemBanners(let items) = section {
                return items.count
            }
        }
        return 0
    }

    func withControllableAddFunds(_ body: (PassthroughSubject<Bool, Never>) async -> Void) async {
        await InjectedDependenciesIsolation.shared.run {
            let subject = PassthroughSubject<Bool, Never>()
            let previous = InjectedValues[\.addFundsBannerVisibilityProvider]
            InjectedValues[\.addFundsBannerVisibilityProvider] = ControllableAddFundsBannerVisibilityProvider(subject: subject)
            defer { InjectedValues[\.addFundsBannerVisibilityProvider] = previous }

            await body(subject)
        }
    }
}

private final class StubNotificationManager: NotificationManager {
    private let subject: CurrentValueSubject<[NotificationViewInput], Never>

    init(inputs: [NotificationViewInput]) {
        subject = CurrentValueSubject(inputs)
    }

    var notificationInputs: [NotificationViewInput] {
        subject.value
    }

    var notificationPublisher: AnyPublisher<[NotificationViewInput], Never> {
        subject.eraseToAnyPublisher()
    }

    func setupManager(with delegate: NotificationTapDelegate?) {}

    func dismissNotification(with id: NotificationViewId) {}
}

private final class ControllableAddFundsBannerVisibilityProvider: AddFundsBannerVisibilityProvider {
    private let subject: PassthroughSubject<Bool, Never>

    init(subject: PassthroughSubject<Bool, Never>) {
        self.subject = subject
    }

    func shouldShowPublisher(for totalBalanceProvider: TotalBalanceProvider) -> AnyPublisher<Bool, Never> {
        subject.eraseToAnyPublisher()
    }
}
