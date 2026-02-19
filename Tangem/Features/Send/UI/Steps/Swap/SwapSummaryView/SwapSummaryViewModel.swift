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

    @Published private(set) var mainButtonIsLoading: Bool = false
    @Published private(set) var mainButtonIsEnabled: Bool = false
    @Published private(set) var mainButtonIcon: MainButton.Icon?
    @Published private(set) var mainButtonState: MainButtonState = .swap

    @Published private(set) var transactionDescription: AttributedString?
    @Published private(set) var alert: AlertBinder?

    private let interactor: SwapSummaryInteractor
    private let notificationManager: NotificationManager
    private let analyticsLogger: SendSummaryAnalyticsLogger

    weak var router: SwapSummaryStepRoutable?

    init(
        interactor: SwapSummaryInteractor,
        notificationManager: NotificationManager,
        analyticsLogger: SendSummaryAnalyticsLogger,
        swapAmountViewModel: SwapAmountViewModel,
        swapSummaryProviderViewModel: SwapSummaryProviderViewModel,
        feeCompactViewModel: SendFeeCompactViewModel,
    ) {
        self.interactor = interactor
        self.notificationManager = notificationManager
        self.analyticsLogger = analyticsLogger
        self.swapAmountViewModel = swapAmountViewModel
        self.swapSummaryProviderViewModel = swapSummaryProviderViewModel
        self.feeCompactViewModel = feeCompactViewModel

        bind()
    }

    func bind(sourceTokenInput: SendSourceTokenInput) {
        sourceTokenInput.sourceTokenPublisher
            .compactMap { $0.value }
            .map { CommonTangemIconProvider(config: $0.userWalletInfo.config).getMainButtonIcon() }
            .assign(to: &$mainButtonIcon)
    }

    func userDidTapSwapProvider() {
        router?.summaryStepRequestEditProviders()
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
    func userDidTapChangeSourceTokenButton(tokenItem: TokenItem) {
        router?.summaryStepRequestEditSourceToken(tokenItem: tokenItem)
    }

    func userDidTapSwapSourceAndReceiveTokensButton() {
        interactor.userDidRequestSwapSourceAndReceiveToken()
    }

    func userDidTapChangeReceiveTokenButton(tokenItem: TokenItem) {
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
