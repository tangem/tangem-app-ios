//
//  SwapSummaryViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemUI
import TangemUIUtils
import TangemLocalization
import TangemMacro

final class SwapSummaryViewModel: ObservableObject, Identifiable {
    @Published private(set) var swapAmountViewModel: SwapAmountViewModel
    @Published private(set) var swapSummaryProviderViewModel: SwapSummaryProviderViewModel
    @Published private(set) var feeCompactViewModel: SendFeeCompactViewModel

    @Published private(set) var notificationInputs: [NotificationViewInput] = []
    @Published private(set) var marketingNotifications: [NotificationBannerItem] = []
    @Published private(set) var notificationButtonIsLoading = false

    @Published private(set) var isMaxAmountButtonHidden: Bool = false
    // Hidden by default: keep the fractions off-screen until the source token balance
    // is confirmed to be strictly positive, otherwise they would flash on a zero balance.
    @Published private(set) var areAmountFractionsHidden: Bool = true
    @Published private(set) var isActionInProcessing: Bool = false

    @Published private(set) var mainButtonIsUpdating: Bool = false
    @Published private(set) var mainButtonIsEnabled: Bool = false
    @Published private(set) var mainButtonIcon: MainButton.Icon?
    @Published private(set) var mainButtonNeedsHold: Bool = false
    @Published private(set) var mainButtonState: MainButtonState = .swap

    @Published private(set) var transactionDescription: AttributedString?
    @Published private(set) var alert: AlertBinder?

    @Published private(set) var formVariant: SwapFormVariant
    @Published var shouldAnimateBestRateBadge: Bool = true

    var mainButtonIsLoading: Bool { isActionInProcessing }

    private let interactor: SwapSummaryInteractor
    private let notificationManager: NotificationManager
    private let marketingNotificationManager: NotificationManager
    private let analyticsLogger: SendSummaryAnalyticsLogger
    private let formVariantResolver: SwapFormVariantResolver
    private let notificationBannerMapper: MultiWalletNotificationBannerMapper

    weak var router: SwapSummaryStepRoutable?

    init(
        interactor: SwapSummaryInteractor,
        notificationManager: NotificationManager,
        marketingNotificationManager: NotificationManager,
        analyticsLogger: SendSummaryAnalyticsLogger,
        swapAmountViewModel: SwapAmountViewModel,
        swapSummaryProviderViewModel: SwapSummaryProviderViewModel,
        feeCompactViewModel: SendFeeCompactViewModel,
        sourceTokenInput: SendSourceTokenInput,
        formVariantResolver: SwapFormVariantResolver = SwapFormVariantResolver(),
        notificationBannerMapper: MultiWalletNotificationBannerMapper = MultiWalletNotificationBannerMapper()
    ) {
        self.interactor = interactor
        self.notificationManager = notificationManager
        self.marketingNotificationManager = marketingNotificationManager
        self.analyticsLogger = analyticsLogger
        self.swapAmountViewModel = swapAmountViewModel
        self.swapSummaryProviderViewModel = swapSummaryProviderViewModel
        self.feeCompactViewModel = feeCompactViewModel
        self.formVariantResolver = formVariantResolver
        self.notificationBannerMapper = notificationBannerMapper
        formVariant = formVariantResolver.currentVariant()

        bind()
        bind(sourceTokenInput: sourceTokenInput)
        applyFormVariant(formVariant)
    }

    func userDidSelectFormVariant(_ variant: SwapFormVariant) {
        guard variant != formVariant else { return }
        let previous = formVariant
        formVariant = variant
        applyFormVariant(variant)
        formVariantResolver.setVariant(variant)
        analyticsLogger.logSwapTypeReselection(from: previous, to: variant)
    }

    func logScreenOpened() {
        analyticsLogger.logSwapTypeScreenOpened(variant: formVariant)
    }

    func makeFormVariantMenu() -> FormVariantMenu {
        let items = SwapFormVariant.allCases.map { variant in
            SendStepNavigationLeadingViewType.DotsMenuItem(
                id: variant.rawValue,
                title: variant.menuTitle,
                action: { [weak self] in self?.userDidSelectFormVariant(variant) }
            )
        }
        return FormVariantMenu(selectedId: formVariant.rawValue, items: items)
    }

    private func applyFormVariant(_ variant: SwapFormVariant) {
        swapAmountViewModel.update(isReceiveFiatHidden: variant == .simple)
    }

    func bind(sourceTokenInput: SendSourceTokenInput) {
        sourceTokenInput.sourceTokenPublisher
            .compactMap { $0.value }
            .map { $0.tangemIconProvider.getMainButtonIcon() }
            .receiveOnMain()
            .assign(to: &$mainButtonIcon)

        sourceTokenInput.sourceTokenPublisher
            .compactMap { $0.value }
            .map { $0.confirmTransactionPolicy.needsHoldToConfirm }
            .receiveOnMain()
            .assign(to: &$mainButtonNeedsHold)
    }

    func userDidTapFee() {
        router?.summaryStepRequestEditFee()
    }

    func userDidTapAmountFraction(_ fraction: SwapAmountFraction) {
        analyticsLogger.logTapAmountFraction(fraction)
        interactor.userDidRequestSourceAmount(fraction: fraction)
    }

    func userDidTapMainActionButton() {
        interactor.userDidRequestSwap()
    }
}

// MARK: - SwapAmountCompactRoutable

extension SwapSummaryViewModel: SwapAmountCompactRoutable {
    func userDidTapChangeSourceTokenButton(receiveToken: SendSourceToken?) {
        router?.summaryStepRequestEditSourceToken(receiveToken: receiveToken?.walletTokenItem)
    }

    func userDidTapSwapSourceAndReceiveTokensButton() {
        interactor.userDidRequestSwapSourceAndReceiveToken()
    }

    func userDidTapChangeReceiveTokenButton(sourceToken: SendSourceToken?) {
        router?.summaryStepRequestEditReceiveToken(sourceToken: sourceToken?.walletTokenItem)
    }
}

// MARK: - SwapSummaryProviderRoutable

extension SwapSummaryViewModel: SwapSummaryProviderRoutable {
    func userDidTapProvider() {
        router?.summaryStepRequestEditProviders()
    }
}

// MARK: - Private

private extension SwapSummaryViewModel {
    func bind() {
        interactor
            .transactionDescription
            .receiveOnMain()
            .assign(to: &$transactionDescription)

        interactor
            .isMaxAmountButtonHiddenPublisher
            .receiveOnMain()
            .assign(to: &$isMaxAmountButtonHidden)

        interactor
            .areAmountFractionsHiddenPublisher
            .receiveOnMain()
            .assign(to: &$areAmountFractionsHidden)

        interactor
            .isNotificationButtonIsLoading
            .receiveOnMain()
            .assign(to: &$notificationButtonIsLoading)

        interactor
            .isReadyToSendPublisher
            .receiveOnMain()
            .assign(to: &$mainButtonIsEnabled)

        interactor
            .mainButtonStatePublisher
            .receiveOnMain()
            .assign(to: &$mainButtonState)

        interactor
            .isUpdatingPublisher
            .receiveOnMain()
            .assign(to: &$mainButtonIsUpdating)

        interactor
            .isActionInProcessing
            .receiveOnMain()
            .assign(to: &$isActionInProcessing)

        notificationManager.notificationPublisher
            .receiveOnMain()
            .assign(to: &$notificationInputs)

        marketingNotificationManager.notificationPublisher
            .map { [notificationBannerMapper] in
                notificationBannerMapper.mapItems($0)
            }
            .assign(to: &$marketingNotifications)
    }
}

// MARK: - Types

extension SwapSummaryViewModel {
    struct FormVariantMenu {
        let selectedId: String
        let items: [SendStepNavigationLeadingViewType.DotsMenuItem]
    }

    @RawCaseName
    enum ProviderState: Identifiable {
        case loading
        case loaded(data: ProviderRowViewModel)
    }

    @RawCaseName
    enum MainButtonState: Identifiable, Equatable {
        case swap
        case transfer

        var title: String {
            switch self {
            case .swap:
                return Localization.swappingSwapAction
            case .transfer:
                return Localization.commonTransfer
            }
        }
    }
}
