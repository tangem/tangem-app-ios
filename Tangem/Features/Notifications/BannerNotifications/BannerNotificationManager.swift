//
//  BannerNotificationManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation
import TangemExpress

class BannerNotificationManager {
    @Injected(\.bannerPromotionService) private var bannerPromotionService: BannerPromotionService
    @Injected(\.onrampRepository) private var onrampRepository: OnrampRepository

    private let notificationInputsSubject: CurrentValueSubject<NotificationViewInput?, Never> = .init(.none)
    private weak var delegate: NotificationTapDelegate?

    private let userWallet: UserWalletModel
    private let placement: BannerPromotionPlacement

    private let activePromotion: CurrentValueSubject<ActivePromotionInfo?, Never> = .init(.none)
    private let analyticsService = NotificationsAnalyticsService()
    private var promotionUpdateTask: Task<Void, Error>?
    private var activePromotionSubscription: AnyCancellable?
    private var sepaPromotionUpdatingSubscription: AnyCancellable?

    init(userWallet: UserWalletModel, placement: BannerPromotionPlacement, contextDataProvider: AnalyticsContextDataProvider?) {
        self.userWallet = userWallet
        self.placement = placement

        analyticsService.setup(with: self, contextDataProvider: contextDataProvider)
        bind()
        load()
    }

    private func load() {
        switch placement {
        case .main:
            loadActivePromotionInfo(programName: .sepa)
        case .tokenDetails:
            break
        }
    }

    private func bind() {
        activePromotionSubscription = activePromotion
            .withWeakCaptureOf(self)
            .flatMapLatest { manager, activePromotion -> AnyPublisher<NotificationViewInput?, Never> in
                guard let activePromotion else {
                    return Just(nil).eraseToAnyPublisher()
                }

                return manager
                    .makeEvent(promotion: activePromotion)
                    .withWeakCaptureOf(manager)
                    .map { manager, event in
                        event.flatMap { manager.makeNotificationViewInput(event: $0) }
                    }
                    .eraseToAnyPublisher()
            }
            .assign(to: \.notificationInputsSubject.value, on: self, ownership: .weak)
    }

    private func loadActivePromotionInfo(programName: PromotionProgramName) {
        promotionUpdateTask?.cancel()
        promotionUpdateTask = runTask(in: self) { manager in
            guard let promotion = await manager.bannerPromotionService.activePromotion(
                promotion: programName,
                on: manager.placement
            ) else {
                await runOnMain { manager.notificationInputsSubject.send(.none) }
                return
            }

            try Task.checkCancellation()
            manager.activePromotion.send(promotion)
        }
    }

    private func makeNotificationViewInput(event: BannerNotificationEvent) -> NotificationViewInput? {
        let buttonAction: NotificationView.NotificationButtonTapAction = { [weak self] id, action in
            self?.delegate?.didTapNotification(with: id, action: action)

            var params = event.analytics.analyticsParams
            params[.action] = Analytics.ParameterValue.clicked.rawValue
            Analytics.log(event: .promotionBannerClicked, params: params)
        }

        let dismissAction: NotificationView.NotificationAction = { [weak self, placement] id in
            self?.bannerPromotionService.hide(promotion: event.programName, on: placement)
            self?.dismissNotification(with: id)

            var params = event.analytics.analyticsParams
            params[.action] = Analytics.ParameterValue.closed.rawValue
            Analytics.log(event: .promotionBannerClicked, params: params)
        }

        let input = NotificationsFactory()
            .buildNotificationInput(for: event, buttonAction: buttonAction, dismissAction: dismissAction)

        return input
    }

    private func makeEvent(promotion: ActivePromotionInfo) -> AnyPublisher<BannerNotificationEvent?, Never> {
        let analytics = BannerNotificationEventAnalyticsParamsBuilder(programName: promotion.bannerPromotion, placement: placement)
        switch promotion.bannerPromotion {
        case .sepa:
            return sepaEvent(promotion: promotion, analytics: analytics)
        }
    }

    private func sepaEvent(promotion: ActivePromotionInfo, analytics: BannerNotificationEventAnalyticsParamsBuilder) -> AnyPublisher<BannerNotificationEvent?, Never> {
        let preferencePublisher = onrampRepository.preferencePublisher.removeDuplicates()
        let bitcoinWalletModel = userWallet.walletModelsManager.walletModelsPublisher
            // If user add / delete bitcoin
            .map { walletModels in
                walletModels.first {
                    $0.isMainToken && $0.tokenItem.blockchain == .bitcoin(testnet: false)
                }
            }

        return Publishers
            .CombineLatest(bitcoinWalletModel, preferencePublisher)
            .asyncMap { [userWalletId = userWallet.userWalletId] bitcoinWalletModel, preference in
                guard let bitcoinWalletModel else {
                    return nil
                }

                let builder = PredefinedOnrampParametersBuilder(
                    userWalletId: userWalletId,
                    onrampPreference: preference
                )

                guard let parameters = await builder.prepare() else {
                    return nil
                }

                return BannerNotificationEvent(
                    programName: promotion.bannerPromotion,
                    analytics: analytics,
                    buttonAction: .init(.openBuyCrypto(walletModel: bitcoinWalletModel, parameters: parameters))
                )
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - NotificationManager

extension BannerNotificationManager: NotificationManager {
    var notificationInputs: [NotificationViewInput] {
        [notificationInputsSubject.value].compactMap(\.self)
    }

    var notificationPublisher: AnyPublisher<[NotificationViewInput], Never> {
        notificationInputsSubject.map { [$0].compactMap(\.self) }.eraseToAnyPublisher()
    }

    func setupManager(with delegate: NotificationTapDelegate?) {
        self.delegate = delegate
    }

    func dismissNotification(with id: NotificationViewId) {
        notificationInputsSubject.send(.none)
    }
}
