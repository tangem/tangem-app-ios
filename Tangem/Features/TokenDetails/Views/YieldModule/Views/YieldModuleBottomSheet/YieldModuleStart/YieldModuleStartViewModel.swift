//
//  YieldModuleStartViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemUI
import SwiftUI
import TangemFoundation
import struct TangemUIUtils.AlertBinder
import TangemSdk
import TangemLocalization
import protocol BlockchainSdk.EthereumFeeParameters

final class YieldModuleStartViewModel: ObservableObject {
    // MARK: - Injected

    @Injected(\.alertPresenter)
    private var alertPresenter: any AlertPresenter

    @Injected(\.floatingSheetPresenter)
    private var floatingSheetPresenter: any FloatingSheetPresenter

    // MARK: - View State

    @Published
    var viewState: ViewState {
        didSet {
            previousState = oldValue
            fetchData(for: viewState)
        }
    }

    let signingActionButtonType: SigningActionButtonViewType

    private var previousState: ViewState?

    // MARK: - Published

    @Published
    private(set) var networkFeeNotification: YieldModuleNotificationBannerParams? = nil

    @Published
    private(set) var highNetworkFeesNotification: YieldModuleNotificationBannerParams? = nil

    @Published
    private(set) var networkFeeState: YieldFeeSectionState

    @Published
    private(set) var isButtonEnabled: Bool = false

    @Published
    private(set) var isNavigationToFeePolicyEnabled: Bool = false

    @Published
    private(set) var minimalAmountState: YieldFeeSectionState = .init()

    @Published
    private(set) var estimatedFeeState: YieldFeeSectionState = .init()

    @Published
    private(set) var maximumFeeState: YieldFeeSectionState = .init()

    @Published
    private(set) var feePolicyFooter: String?

    @Published
    private(set) var rateInfoContent: RateInfoChartContent = .loading

    @Published
    var incentivePeriod: YieldIncentiveChartPeriod = .week {
        didSet {
            guard incentivePeriod != oldValue else { return }
            fetchRateInfoChart()
        }
    }

    /// Fixed at init: every entry point already has the market loaded, so the campaign copy never changes mid-flight.
    let marketIncentive: YieldModuleMarketIncentive?

    private let currentApy: Decimal?

    @Published
    private(set) var isProcessingStartRequest: Bool = false

    // MARK: - Dependencies

    private(set) var walletModel: any WalletModel
    private weak var coordinator: YieldModulePromoCoordinator?
    private let yieldManagerInteractor: YieldManagerInteractor
    private let notificationManager: YieldModuleNotificationManager
    private let logger: YieldAnalyticsLogger
    private let percentFormatter = PercentFormatter()
    private lazy var feeConverter = YieldModuleFeeFormatter(feeCurrency: walletModel.feeTokenItem, token: walletModel.tokenItem)

    // MARK: - Properties

    private(set) var maximumFee: Decimal = 0

    private var rateInfoChartTask: Task<Void, Never>?

    // MARK: - Init

    init(
        walletModel: any WalletModel,
        viewState: ViewState,
        marketIncentive: YieldModuleMarketIncentive?,
        currentApy: Decimal?,
        coordinator: YieldModulePromoCoordinator?,
        yieldManagerInteractor: YieldManagerInteractor,
        logger: YieldAnalyticsLogger,
        signingActionButtonType: SigningActionButtonViewType
    ) {
        self.viewState = viewState
        self.marketIncentive = marketIncentive
        self.currentApy = currentApy
        self.walletModel = walletModel
        self.coordinator = coordinator
        self.yieldManagerInteractor = yieldManagerInteractor
        self.logger = logger
        self.signingActionButtonType = signingActionButtonType

        networkFeeState = .init(
            footerText: Localization.yieldModuleStartEarningSheetNextDepositsV2(walletModel.tokenItem.currencySymbol),
            isLinkActive: false
        )

        notificationManager = YieldModuleNotificationManager(tokenItem: walletModel.tokenItem, feeTokenItem: walletModel.feeTokenItem)
        fetchData(for: viewState)
    }

    // MARK: - Navigation

    func onCloseTap() {
        Task { @MainActor [weak self] in
            self?.floatingSheetPresenter.removeActiveSheet()
        }
    }

    @MainActor
    func onShowFeePolicy() {
        logger.logEarningButtonFeePolicy()
        viewState = .feePolicy
    }

    @MainActor
    func onStartEarnTap() {
        let token = walletModel.tokenItem
        isProcessingStartRequest = true
        logger.logEarningButtonStart()

        Task { @MainActor [weak self] in
            defer { self?.isProcessingStartRequest = false }

            do {
                try await self?.yieldManagerInteractor.enter(with: token)
                self?.logger.logEarningFundsEarned()
                self?.coordinator?.dismiss()
            } catch let error where error.isCancellationError {
                // Do nothing
            } catch {
                self?.logger.logEarningErrors(action: .start, error: error)
                self?.alertPresenter.present(alert: AlertBuilder.makeOkErrorAlert(message: error.localizedDescription))
            }
        }
    }

    @MainActor
    func onBackAction() {
        previousState.map { viewState = $0 }
    }

    var currentIncentiveApyFormatted: String {
        currentApy.map { percentFormatter.format($0, option: .earn) } ?? AppConstants.emDashSign
    }

    func retryRateInfoChart() {
        fetchRateInfoChart()
    }

    // MARK: - Public Implementation

    private func fetchRateInfoChart() {
        rateInfoChartTask?.cancel()
        rateInfoChartTask = Task { @MainActor [weak self] in
            guard let self else { return }

            rateInfoContent = .loading

            do {
                if case .incentiveRateInfo = viewState {
                    let period = incentivePeriod
                    let data = try await yieldManagerInteractor.getIncentiveChartData(period: period)
                    // The awaited call may outlive a period switch; only the still-selected period may write.
                    guard !Task.isCancelled, period == incentivePeriod else { return }
                    rateInfoContent = data.baseApyData.isEmpty ? .unavailable : .incentive(data)
                } else {
                    let data = try await yieldManagerInteractor.getChartData()
                    guard !Task.isCancelled else { return }
                    rateInfoContent = .legacy(data)
                }
            } catch let error where error.isCancellationError {
                // A newer fetch owns the content.
            } catch {
                guard !Task.isCancelled else { return }
                rateInfoContent = .error
            }
        }
    }

    private func fetchFees() {
        Task { @MainActor [self] in
            setAllFeesState(.loading)

            do {
                let feeParameters = try await yieldManagerInteractor.getCurrentFeeParameters()

                async let networkFee: Void = fetchNetworkFee()
                async let minimalAmount: Void = fetchMinimalAmount(feeParameters: feeParameters)
                async let estimatedAndMaximumFee: Void = fetchEstimatedAndMaximumFee(feeParameters: feeParameters)

                _ = await (networkFee, minimalAmount, estimatedAndMaximumFee)
            } catch {
                isButtonEnabled = false
                setAllFeesState(.noData)
                highNetworkFeesNotification = nil
                networkFeeNotification = createFeeErrorNotification { [weak self] in
                    await self?.reloadAction()
                }
            }
        }
    }

    @MainActor
    private func fetchMinimalAmount(feeParameters: EthereumFeeParameters) async {
        minimalAmountState = minimalAmountState.withFeeState(.loading)

        do {
            let minimalAmountInFiat = try await yieldManagerInteractor.getMinAmount(feeParameters: feeParameters)
            let minimalFeeFormatted = try await feeConverter.makeFormattedMinimalFee(from: minimalAmountInFiat)

            minimalAmountState = minimalAmountState
                .withFeeState(.loaded(text: minimalFeeFormatted.fiatFee))
                .withFooterText(Localization.yieldModuleFeePolicySheetMinAmountNote(minimalFeeFormatted.fiatFee, minimalFeeFormatted.cryptoFee))
        } catch {
            minimalAmountState = minimalAmountState
                .withFeeState(.noData)
                .withFooterText(nil)
        }
    }

    // MARK: - Private Implementation

    private func fetchData(for state: ViewState) {
        switch state {
        case .rateInfo, .incentiveRateInfo:
            fetchRateInfoChart()
        case .startEarning:
            fetchFees()
        case .feePolicy:
            break
        }
    }

    @MainActor
    private func fetchNetworkFee() async {
        networkFeeNotification = nil
        highNetworkFeesNotification = nil
        isButtonEnabled = false
        isNavigationToFeePolicyEnabled = false

        do {
            let feeInCoins = try await yieldManagerInteractor.getEnterFee()
            let feeValue = feeInCoins.totalFeeAmount.value
            let fiatFee = try await feeConverter.createFeeString(from: feeValue)
            let isGasPriceHigh = await yieldManagerInteractor.isGasPriceHigh(in: feeInCoins)

            networkFeeState = networkFeeState
                .withFeeState(.loaded(text: fiatFee))
                .withLinkActive(true)

            let feeCurrencyBalance = walletModel.getFeeCurrencyBalance()
            let isFeeHigh = feeValue > feeCurrencyBalance

            if case .ethereum = walletModel.tokenItem.blockchain, isGasPriceHigh, !isFeeHigh {
                logger.logEarningNoticeHighNetworkFeeShown()
                highNetworkFeesNotification = createHighNetworkFeesNotification()
            }

            if isFeeHigh {
                logger.logEarningNoticeNotEnoughFeeShown(feeCurrencyBalance: feeCurrencyBalance)
                networkFeeNotification = createNotEnoughFeeNotification(walletModel: walletModel)
            }

            isNavigationToFeePolicyEnabled = true
            isButtonEnabled = !isFeeHigh
        } catch {
            networkFeeNotification = createFeeErrorNotification { [weak self] in
                await self?.reloadAction()
            }

            highNetworkFeesNotification = nil
            networkFeeState = networkFeeState.withFeeState(.noData).withLinkActive(false)
            isButtonEnabled = false
        }
    }

    @MainActor
    private func fetchEstimatedAndMaximumFee(feeParameters: EthereumFeeParameters) async {
        guard let maxFeeNative = await yieldManagerInteractor.getMaxFeeNative() else {
            estimatedFeeState = estimatedFeeState.withFeeState(.noData)
            maximumFeeState = maximumFeeState.withFeeState(.noData)
            return
        }

        do {
            let estimatedFee = try await yieldManagerInteractor.getCurrentNetworkFee(feeParameters: feeParameters)

            let estimatedFeeFormatted = try await feeConverter.makeFormattedMinimalFee(from: estimatedFee)
            let maxFeeFormatted = try await feeConverter.makeFormattedMaximumFee(maxFeeNative: maxFeeNative)

            estimatedFeeState = estimatedFeeState.withFeeState(.loaded(text: estimatedFeeFormatted.fiatFee))
            maximumFeeState = maximumFeeState.withFeeState(.loaded(text: maxFeeFormatted.fiatFee))

            feePolicyFooter = Localization.yieldModuleFeePolicySheetFeeNote(
                estimatedFeeFormatted.fiatFee,
                estimatedFeeFormatted.cryptoFee,
                maxFeeFormatted.fiatFee,
                maxFeeFormatted.cryptoFee
            )
        } catch {
            estimatedFeeState = estimatedFeeState.withFeeState(.noData)
            maximumFeeState = maximumFeeState.withFeeState(.noData)
            feePolicyFooter = nil
        }
    }

    @MainActor
    private func reloadAction() async {
        networkFeeNotification = nil
        highNetworkFeesNotification = nil
        setAllFeesState(.loading)
        await walletModel.update(silent: true, options: .balances)
        fetchFees()
    }

    @MainActor
    private func setAllFeesState(_ state: LoadableTextView.State) {
        networkFeeState = networkFeeState.withFeeState(state)
        estimatedFeeState = estimatedFeeState.withFeeState(state)
        maximumFeeState = maximumFeeState.withFeeState(state)
        minimalAmountState = minimalAmountState.withFeeState(state)
    }
}

// MARK: - Rate-info chart content

extension YieldModuleStartViewModel {
    enum RateInfoChartContent: Equatable {
        case loading
        case legacy(YieldChartData)
        case incentive(YieldIncentiveChartData)
        case unavailable
        case error
    }
}

// MARK: - View State

extension YieldModuleStartViewModel {
    enum ViewState: Identifiable, Equatable {
        case rateInfo
        case incentiveRateInfo
        case feePolicy
        case startEarning

        // MARK: - Identifiable

        var id: String {
            switch self {
            case .rateInfo:
                "rateInfo"
            case .incentiveRateInfo:
                "incentiveRateInfo"
            case .feePolicy:
                "feePolicy"
            case .startEarning:
                "startEarning"
            }
        }
    }
}

// MARK: - FloatingSheetContentViewModel

extension YieldModuleStartViewModel: FloatingSheetContentViewModel {}

// MARK: - Notification Builders

private extension YieldModuleStartViewModel {
    func createNotEnoughFeeNotification(walletModel: any WalletModel) -> YieldModuleNotificationBannerParams {
        notificationManager.createNotEnoughFeeCurrencyNotification { [weak self] in
            self?.coordinator?.openFeeCurrency(walletModel: walletModel)
        }
    }

    func createFeeErrorNotification(reloadAction: @MainActor @escaping () async -> Void) -> YieldModuleNotificationBannerParams {
        notificationManager.createFeeUnreachableNotification {
            Task {
                await reloadAction()
            }
        }
    }

    func createHighNetworkFeesNotification() -> YieldModuleNotificationBannerParams {
        notificationManager.createHighFeesNotification()
    }
}
