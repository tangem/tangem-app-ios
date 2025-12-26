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

    @Injected(\.userWalletRepository)
    private var userWalletRepository: any UserWalletRepository

    // MARK: - View State

    @Published
    var viewState: ViewState {
        didSet {
            previousState = oldValue
            fetchData(for: viewState)
        }
    }

    private var previousState: ViewState?

    // MARK: - Published

    @Published
    var alert: AlertBinder?

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
    private(set) var chartState: YieldChartContainerState = .loading

    @Published
    private(set) var isProcessingStartRequest: Bool = false

    // MARK: - Dependencies

    private(set) var walletModel: any WalletModel
    private weak var coordinator: YieldModulePromoCoordinator?
    private let yieldManagerInteractor: YieldManagerInteractor
    private let notificationManager: YieldModuleNotificationManager
    private let logger: YieldAnalyticsLogger
    private lazy var feeConverter = YieldModuleFeeFormatter(feeCurrency: walletModel.feeTokenItem, token: walletModel.tokenItem)

    // MARK: - Properties

    private(set) var maximumFee: Decimal = 0

    // MARK: - Init

    init(
        walletModel: any WalletModel,
        viewState: ViewState,
        coordinator: YieldModulePromoCoordinator?,
        yieldManagerInteractor: YieldManagerInteractor,
        logger: YieldAnalyticsLogger
    ) {
        self.viewState = viewState
        self.walletModel = walletModel
        self.coordinator = coordinator
        self.yieldManagerInteractor = yieldManagerInteractor
        self.logger = logger

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

    // MARK: - Public Implementation

    private func fetchChartData() {
        Task { @MainActor [weak self] in
            self?.chartState = .loading

            do {
                let chartData = try await self?.yieldManagerInteractor.getChartData()

                if let chartData {
                    self?.chartState = .loaded(chartData)
                } else {
                    self?.chartState = .error(action: { [weak self] in
                        self?.fetchChartData()
                    })
                }
            } catch {
                self?.chartState = .error(action: { [weak self] in
                    self?.fetchChartData()
                })
            }
        }
    }

    private func fetchFees() {
        Task { @MainActor in
            setAllFeesState(.loading)

            do {
                let feeParameters = try await yieldManagerInteractor.getCurrentFeeParameters()

                async let networkFee: () = fetchNetworkFee()
                async let minimalAmount: () = fetchMinimalAmount(feeParameters: feeParameters)
                async let estimatedAndMaximumFee: () = fetchEstimatedAndMaximumFee(feeParameters: feeParameters)

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
        case .rateInfo:
            fetchChartData()
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

            let isFeeHigh = feeValue > walletModel.getFeeCurrencyBalance()

            if case .ethereum = walletModel.tokenItem.blockchain, isGasPriceHigh, !isFeeHigh {
                logger.logEarningNoticeHighNetworkFeeShown()
                highNetworkFeesNotification = createHighNetworkFeesNotification()
            }

            if isFeeHigh {
                logger.logEarningNoticeNotEnoughFeeShown()
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
        await walletModel.update(silent: true, features: .balances)
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

// MARK: - View State

extension YieldModuleStartViewModel {
    enum ViewState: Identifiable, Equatable {
        case rateInfo
        case feePolicy
        case startEarning

        // MARK: - Identifiable

        var id: String {
            switch self {
            case .rateInfo:
                "rateInfo"
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
