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
    private let analyticsLogger: SendSummaryAnalyticsLogger
    private let formVariantResolver: SwapFormVariantResolver

    weak var router: SwapSummaryStepRoutable?

    init(
        interactor: SwapSummaryInteractor,
        notificationManager: NotificationManager,
        analyticsLogger: SendSummaryAnalyticsLogger,
        swapAmountViewModel: SwapAmountViewModel,
        swapSummaryProviderViewModel: SwapSummaryProviderViewModel,
        feeCompactViewModel: SendFeeCompactViewModel,
        sourceTokenInput: SendSourceTokenInput,
        formVariantResolver: SwapFormVariantResolver = SwapFormVariantResolver()
    ) {
        self.interactor = interactor
        self.notificationManager = notificationManager
        self.analyticsLogger = analyticsLogger
        self.swapAmountViewModel = swapAmountViewModel
        self.swapSummaryProviderViewModel = swapSummaryProviderViewModel
        self.feeCompactViewModel = feeCompactViewModel
        self.formVariantResolver = formVariantResolver
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
        guard FeatureProvider.isAvailable(.swapSimpleMode) else { return }
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

    // [REDACTED_TODO_COMMENT]
    func userDidTapMaxAmount() {
        interactor.userDidRequestMaxAmount()
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
    func userDidTapChangeSourceTokenButton(tokenItem: TokenItem?) {
        router?.summaryStepRequestEditSourceToken(tokenItem: tokenItem)
    }

    func userDidTapSwapSourceAndReceiveTokensButton() {
        interactor.userDidRequestSwapSourceAndReceiveToken()
    }

    func userDidTapChangeReceiveTokenButton(tokenItem: TokenItem?) {
        router?.summaryStepRequestEditReceiveToken(tokenItem: tokenItem)
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
            .isUpdatingPublisher
            .receiveOnMain()
            .assign(to: &$mainButtonIsUpdating)

        interactor
            .isActionInProcessing
            .receiveOnMain()
            .assign(to: &$isActionInProcessing)

        notificationManager
            .notificationPublisher
            .receiveOnMain()
            .assign(to: &$notificationInputs)
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
    enum MainButtonState: Identifiable {
        case swap
        case insufficientFunds
        case permitAndSwap

        var title: String {
            switch self {
            case .swap:
                return Localization.swappingSwapAction
            case .insufficientFunds:
                return Localization.swappingInsufficientFunds
            case .permitAndSwap:
                return Localization.swappingPermitAndSwap
            }
        }

        func getIcon(tangemIconProvider: TangemIconProvider) -> MainButton.Icon? {
            switch self {
            case .swap, .permitAndSwap:
                return tangemIconProvider.getMainButtonIcon()
            case .insufficientFunds:
                return .none
            }
        }
    }
}
