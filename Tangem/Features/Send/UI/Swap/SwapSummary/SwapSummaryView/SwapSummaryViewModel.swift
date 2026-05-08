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
    @Published private(set) var isActionInProcessing: Bool = false

    @Published private(set) var mainButtonIsUpdating: Bool = false
    @Published private(set) var mainButtonIsEnabled: Bool = false
    @Published private(set) var mainButtonIcon: MainButton.Icon?
    @Published private(set) var mainButtonNeedsHold: Bool = false
    @Published private(set) var mainButtonState: MainButtonState = .swap

    @Published private(set) var transactionDescription: AttributedString?
    @Published private(set) var alert: AlertBinder?

    @Published var displayMode: SwapDisplayMode
    @Published var shouldAnimateBestRateBadge: Bool = false

    var mainButtonIsLoading: Bool { isActionInProcessing }

    private let interactor: SwapSummaryInteractor
    private let notificationManager: NotificationManager
    private let analyticsLogger: SendSummaryAnalyticsLogger
    private let displayModeResolver: SwapDisplayModeResolver

    weak var router: SwapSummaryStepRoutable?

    init(
        interactor: SwapSummaryInteractor,
        notificationManager: NotificationManager,
        analyticsLogger: SendSummaryAnalyticsLogger,
        swapAmountViewModel: SwapAmountViewModel,
        swapSummaryProviderViewModel: SwapSummaryProviderViewModel,
        feeCompactViewModel: SendFeeCompactViewModel,
        sourceTokenInput: SendSourceTokenInput,
        displayModeResolver: SwapDisplayModeResolver = SwapDisplayModeResolver()
    ) {
        self.interactor = interactor
        self.notificationManager = notificationManager
        self.analyticsLogger = analyticsLogger
        self.swapAmountViewModel = swapAmountViewModel
        self.swapSummaryProviderViewModel = swapSummaryProviderViewModel
        self.feeCompactViewModel = feeCompactViewModel
        self.displayModeResolver = displayModeResolver
        displayMode = displayModeResolver.currentMode()

        bind()
        bind(sourceTokenInput: sourceTokenInput)
        applyDisplayMode(displayMode)
    }

    func userDidSelectDisplayMode(_ mode: SwapDisplayMode) {
        guard mode != displayMode else { return }
        displayMode = mode
        applyDisplayMode(mode)
        displayModeResolver.setMode(mode)
    }

    func makeDisplayModeMenuItems() -> [SendStepNavigationLeadingViewType.DotsMenuItem] {
        SwapDisplayMode.allCases.map { mode in
            .init(
                id: mode.rawValue,
                title: mode.menuTitle,
                isSelected: mode == displayMode,
                action: { [weak self] in self?.userDidSelectDisplayMode(mode) }
            )
        }
    }

    private func applyDisplayMode(_ mode: SwapDisplayMode) {
        swapAmountViewModel.update(isReceiveFiatHidden: mode == .simple)
    }

    func bind(sourceTokenInput: SendSourceTokenInput) {
        sourceTokenInput.sourceTokenPublisher
            .compactMap { $0.value }
            .map { $0.tangemIconProvider.getMainButtonIcon() }
            .receiveOnMain()
            .assign(to: &$mainButtonIcon)

        sourceTokenInput.sourceTokenPublisher
            .compactMap { $0.value }
            .map { CommonConfirmTransactionPolicy(userWalletInfo: $0.userWalletInfo).needsHoldToConfirm }
            .receiveOnMain()
            .assign(to: &$mainButtonNeedsHold)
    }

    func userDidTapFee() {
        router?.summaryStepRequestEditFee()
    }

    func userDidTapMaxAmount() {
        interactor.userDidRequestMaxAmount()
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
