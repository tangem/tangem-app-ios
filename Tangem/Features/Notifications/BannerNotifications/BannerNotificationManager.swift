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
import TangemLocalization
import BlockchainSdk

class BannerNotificationManager {
    @Injected(\.bannerPromotionService) private var bannerPromotionService: BannerPromotionService
    @Injected(\.onrampRepository) private var onrampRepository: OnrampRepository

    private let notificationInputsSubject: CurrentValueSubject<[NotificationViewInput], Never> = .init([])
    private weak var delegate: NotificationTapDelegate?

    private let userWalletInfo: UserWalletInfo
    private let userWalletModel: UserWalletModel?
    private let placement: BannerPromotionPlacement

    private let analyticsService: NotificationsAnalyticsService

    private let activePromotions: CurrentValueSubject<[ActivePromotionInfo], Never> = .init([])
    private var promotionUpdateTasks: [PromotionProgramName: Task<Void, Error>] = [:]
    private var analyticsSubscription: AnyCancellable?
    private var activePromotionSubscription: AnyCancellable?

    init(
        userWalletInfo: UserWalletInfo,
        userWalletModel: UserWalletModel? = nil,
        placement: BannerPromotionPlacement
    ) {
        self.userWalletInfo = userWalletInfo
        self.userWalletModel = userWalletModel
        self.placement = placement

        analyticsService = NotificationsAnalyticsService(userWalletId: userWalletInfo.id)

        bind()
        load()
    }

    private func load() {
        switch placement {
        case .main:
            loadActivePromotions()
        case .tokenDetails:
            break
        }
    }

    private func bind() {
        analyticsSubscription = notificationPublisher
            .debounce(for: 0.1, scheduler: DispatchQueue.main)
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink(receiveValue: { manager, notifications in
                manager.analyticsService.sendEventsIfNeeded(for: notifications)
            })

        let promotionsPublisher = makePromotionsInputsPublisher()
        let cloreMigrationPublisher = makeCloreMigrationInputsPublisher()

        activePromotionSubscription = Publishers.CombineLatest(promotionsPublisher, cloreMigrationPublisher)
            .map { $0 + $1 }
            .receiveOnMain()
            .assign(to: \.notificationInputsSubject.value, on: self, ownership: .weak)
    }

    private func makePromotionsInputsPublisher() -> AnyPublisher<[NotificationViewInput], Never> {
        activePromotions
            .withWeakCaptureOf(self)
            .flatMapLatest { manager, activePromotions -> AnyPublisher<[NotificationViewInput], Never> in
                guard !activePromotions.isEmpty else {
                    return Just([]).eraseToAnyPublisher()
                }

                let eventPublishers = activePromotions.map { promotion in
                    manager.makeEvent(promotion: promotion)
                        .first()
                        .withWeakCaptureOf(manager)
                        .map { manager, event -> NotificationViewInput? in
                            event.flatMap { manager.makeNotificationViewInput(event: $0) }
                        }
                }

                return Publishers.MergeMany(eventPublishers)
                    .collect()
                    .map { $0.compactMap { $0 } }
                    .receiveOnMain()
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    private func makeCloreMigrationInputsPublisher() -> AnyPublisher<[NotificationViewInput], Never> {
        guard case .main = placement, let userWalletModel else {
            return Just([]).eraseToAnyPublisher()
        }

        return AccountsFeatureAwareWalletModelsResolver
            .walletModelsPublisher(for: userWalletModel)
            .map { $0.filter { $0.tokenItem.blockchain == .clore } }
            .map { walletModels -> AnyPublisher<[TokenBalanceType], Never> in
                guard !walletModels.isEmpty else {
                    return Just([TokenBalanceType]()).eraseToAnyPublisher()
                }

                return walletModels
                    .map { $0.totalTokenBalanceProvider.balanceTypePublisher }
                    .combineLatest()
            }
            .switchToLatest()
            .map { balances in
                balances.compactMap { $0.value }.contains(where: { $0 > 0 })
            }
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .map { manager, hasBalance in
                hasBalance ? [manager.makeCloreMigrationNotification()] : []
            }
            .eraseToAnyPublisher()
    }

    private func makeCloreMigrationNotification() -> NotificationViewInput {
        NotificationsFactory()
            .buildNotificationInput(
                for: TokenNotificationEvent.cloreMigration,
                buttonAction: { [weak self] id, action in
                    self?.delegate?.didTapNotification(with: id, action: action)
                }
            )
    }

    private func loadActivePromotions() {
        runTask(in: self) { manager in
            let activePromotions = await manager.bannerPromotionService.loadActivePromotionsFor(
                walletId: manager.userWalletInfo.id.stringValue, on: manager.placement
            )

            await runOnMain {
                activePromotions.forEach { manager.addOrUpdatePromotion($0) }
            }
        }
    }

    private func addOrUpdatePromotion(_ promotion: ActivePromotionInfo) {
        var currentPromotions = activePromotions.value
        // Remove existing promotion with the same name if exists
        currentPromotions.removeAll { $0.bannerPromotion == promotion.bannerPromotion }
        // Add new promotion
        currentPromotions.append(promotion)
        activePromotions.send(currentPromotions)
    }

    private func removePromotion(programName: PromotionProgramName) {
        var currentPromotions = activePromotions.value
        currentPromotions.removeAll { $0.bannerPromotion == programName }
        activePromotions.send(currentPromotions)
    }

    private func makeNotificationViewInput(event: BannerNotificationEvent) -> NotificationViewInput? {
        let buttonAction: NotificationView.NotificationButtonTapAction = { [weak self] id, action in
            self?.delegate?.didTapNotification(with: id, action: action)

            switch event.programName {
            case .yield:
                var params = event.analytics.analyticsParams
                params[.action] = Analytics.ParameterValue.clicked.rawValue
                Analytics.log(event: .promotionBannerClicked, params: params)
            }
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

        return event(
            promotion: promotion,
            analytics: analytics
        )
    }

    private func event(
        promotion: ActivePromotionInfo,
        analytics: BannerNotificationEventAnalyticsParamsBuilder
    ) -> AnyPublisher<BannerNotificationEvent?, Never> {
        let buttonAction: NotificationButtonAction? = promotion.link.map { link in
            .init(.openLink(
                promotionLink: link,
                buttonTitle: promotion.bannerPromotion.buttonTitle
            ))
        }

        let event = BannerNotificationEvent(
            programName: promotion.bannerPromotion,
            analytics: analytics,
            buttonAction: buttonAction
        )

        return .just(output: event)
    }
}

// MARK: - NotificationManager

extension BannerNotificationManager: NotificationManager {
    var notificationInputs: [NotificationViewInput] {
        notificationInputsSubject.value
    }

    var notificationPublisher: AnyPublisher<[NotificationViewInput], Never> {
        notificationInputsSubject.eraseToAnyPublisher()
    }

    func setupManager(with delegate: NotificationTapDelegate?) {
        self.delegate = delegate
    }

    func dismissNotification(with id: NotificationViewId) {
        var currentInputs = notificationInputsSubject.value
        currentInputs.removeAll { $0.id == id }
        notificationInputsSubject.send(currentInputs)
    }
}
