//
//  YieldModuleActiveViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BigInt
import TangemUI
import TangemFoundation
import TangemLocalization
import TangemAssets
import TangemSdk
import SwiftUI

final class YieldModuleActiveViewModel: ObservableObject {
    // MARK: - Injected

    @Injected(\.userWalletRepository)
    private var userWalletRepository: any UserWalletRepository

    @Injected(\.marketingCampaignsRepository)
    private var marketingCampaignsRepository: MarketingCampaignsRepository

    // MARK: - Published

    @Published
    private(set) var earnInfoNotifications = [YieldModuleNotificationBannerParams]()

    @Published
    private(set) var standaloneMarketingBanners: [StandaloneMarketingBannerViewModel]?

    @Published
    private(set) var apyState: LoadableTextView.State = .loading

    @Published
    private(set) var minimalAmountState: YieldFeeSectionState = .init()

    @Published
    private(set) var estimatedFeeState: YieldFeeSectionState = .init()

    @Published
    private(set) var availableBalanceState: YieldFeeSectionState = .init()

    @Published
    private(set) var earInfoFooterText: AttributedString?

    @Published
    private(set) var chartState: YieldChartContainerState = .loading

    @Published
    private(set) var apyTrend: ApyTrend = .none

    @Published
    private(set) var rewardsBannerData: YieldModuleRewardsBannerView.ViewData?

    @Published
    private(set) var apyBreakdown: YieldApyBreakdown?

    private var maxFee: String?

    // MARK: - Promo State

    @Published
    private(set) var promoStatus: YieldPromoStatus = .undefined

    @Published
    private var isBonusPaidOutBannerDismissed = false

    private let yieldPromoStatusProvider = YieldPromoStatusProvider()
    private var daysLeftToUnlockBonus: Int?

    var promoBonusText: String? {
        switch promoStatus {
        case .active:
            daysLeftToUnlockBonus.map { days in
                "\(days) \(Localization.commonDaysNoParam(days)) \(Localization.yieldPromoLeftTitle)"
            }

        case .completed:
            Localization.yieldPromoCompleted

        case .notStarted, .undefined:
            nil
        }
    }

    var showsBonusPaidOutBanner: Bool {
        promoStatus == .completed && !isBonusPaidOutBannerDismissed
    }

    // MARK: - Dependencies

    private(set) var walletModel: any WalletModel
    private weak var coordinator: YieldModuleActiveCoordinator?
    private lazy var feeConverter = YieldModuleFeeFormatter(feeCurrency: walletModel.feeTokenItem, token: walletModel.tokenItem)
    private lazy var dustFilter = YieldModuleDustFilter(feeConverter: feeConverter)

    private let transactionFlowFactory: YieldModuleTransactionFlowFactory
    private let yieldManagerInteractor: YieldManagerInteractor
    private let marketInfoPublisher: AnyPublisher<YieldModuleMarketInfo?, Never>
    private let notificationManager: YieldModuleNotificationManager
    private let marketingBannerManager = MarketingBannerManager()
    private let logger: YieldAnalyticsLogger

    // MARK: - Properties

    private(set) var activityState: ActivityState = .active
    private(set) var readMoreURL = TangemBlogUrlBuilder().url(post: .yieldMode)
    private var minimalTopupAmountInFiat: Decimal?
    private var bag = Set<AnyCancellable>()
    private var marketStateTask: Task<Void, Never>?

    // MARK: - Init

    init(
        walletModel: any WalletModel,
        coordinator: YieldModuleActiveCoordinator?,
        transactionFlowFactory: YieldModuleTransactionFlowFactory,
        yieldManagerInteractor: YieldManagerInteractor,
        marketInfoPublisher: AnyPublisher<YieldModuleMarketInfo?, Never>,
        notificationManager: YieldModuleNotificationManager,
        logger: YieldAnalyticsLogger
    ) {
        self.walletModel = walletModel
        self.coordinator = coordinator
        self.transactionFlowFactory = transactionFlowFactory
        self.yieldManagerInteractor = yieldManagerInteractor
        self.marketInfoPublisher = marketInfoPublisher
        self.logger = logger
        self.notificationManager = notificationManager

        logger.logEarningInProgressScreenOpened()

        bind()
        start()
    }

    // MARK: - Navigation

    func onBackButtonTap() {
        coordinator?.dismiss()
    }

    func onShowStopEarningSheet() {
        coordinator?.openBottomSheet(
            viewModel: transactionFlowFactory.makeTransactionViewModel(
                action: .stop(tokenName: walletModel.tokenItem.name)
            )
        )
    }

    func onPromoBonusTap() {
        coordinator?.openYieldApyBoostStory()
    }

    func onApyInfoTap() {
        guard let apyBreakdown else { return }

        coordinator?.openAboutApySheet(
            viewModel: YieldModuleAboutApyViewModel(baseApy: apyBreakdown.baseApy, rewardsApr: apyBreakdown.rewardsApr)
        )
    }

    func onClaimTap() {
        // The claim sheet arrives with the claim part of the Merkl incentives series.
    }

    // MARK: - Public Implementation

    func openReadMore() {
        let url = readMoreURL
        Task { @MainActor [weak self] in
            self?.coordinator?.openUrl(url: url)
        }
    }

    func makeMyFundsSectionText() -> AttributedString {
        let symbol = walletModel.tokenItem.currencySymbol
        let prefixedSymbol = "a\(walletModel.tokenItem.currencySymbol)"
        let fullString = Localization.yieldModuleEarnSheetProviderDescription(symbol, prefixedSymbol) + " " + Localization.commonReadMore

        var attr = AttributedString(fullString)
        attr.font = Fonts.Regular.caption1
        attr.foregroundColor = Colors.Text.tertiary

        if let range = attr.range(of: Localization.commonReadMore) {
            attr[range].foregroundColor = Colors.Text.accent
            attr[range].link = readMoreURL
        }

        return attr
    }

    // MARK: - Private Implementation

    private func start() {
        Task { await getAvailableFunds() }
        Task {
            await getEarnInfoFees()
            await checkWarnings()
        }
        Task { await fetchChartData() }
        Task { await getYieldPromoData() }
    }

    private func bind() {
        marketingBannerManager.setup(
            bannersPublisher: marketingCampaignsRepository.bannersPublisher(for: walletModel.tokenItem, kind: .yield)
        )

        marketingBannerManager.standaloneBannersPublisher
            .map { $0.nilIfEmpty }
            .assign(to: &$standaloneMarketingBanners)

        marketInfoPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refreshMarketState()
            }
            .store(in: &bag)
    }

    private func refreshMarketState() {
        marketStateTask?.cancel()
        marketStateTask = Task { @MainActor [weak self] in
            await self?.getApy()

            guard !Task.isCancelled else {
                return
            }

            await self?.getIncentives()
        }
    }

    @MainActor
    private func getIncentives() async {
        let breakdown = await yieldManagerInteractor.getApyBreakdown()
        let hasActiveCampaign = await yieldManagerInteractor.hasActiveIncentiveCampaign()

        guard !Task.isCancelled else {
            return
        }

        apyBreakdown = breakdown

        let summary = hasActiveCampaign ? await yieldManagerInteractor.getIncentivesSummary() : nil

        guard !Task.isCancelled else {
            return
        }

        let surfaceState = YieldIncentivesSurfaceState.make(
            campaignActive: hasActiveCampaign,
            summary: summary,
            isClaimInFlight: false
        )

        rewardsBannerData = makeRewardsBannerData(surfaceState: surfaceState, summary: summary)
    }

    @MainActor
    private func getYieldPromoData() async {
        await yieldPromoStatusProvider.refreshPromoStatusIfEligible(
            userWalletId: walletModel.userWalletId.stringValue,
            tokenItem: walletModel.tokenItem
        )

        let promoState = await yieldPromoStatusProvider.promoState(
            userWalletId: walletModel.userWalletId.stringValue,
            tokenItem: walletModel.tokenItem
        )

        daysLeftToUnlockBonus = promoState.daysLeftToUnlockBonus
        promoStatus = promoState.status
    }

    @MainActor
    private func getAvailableFunds() async {
        if let availableBalance = await yieldManagerInteractor.getAvailableBalance() {
            availableBalanceState = availableBalanceState.withFeeState(
                .loaded(text: feeConverter.formatCryptoBalance(availableBalance, prefix: "a"))
            )
        } else {
            availableBalanceState = availableBalanceState.withFeeState(.noData)
        }
    }

    @MainActor
    private func getEarnInfoFees() async {
        minimalAmountState = minimalAmountState.withFeeState(.loading)
        estimatedFeeState = estimatedFeeState.withFeeState(.loading)
        maxFee = nil
        minimalTopupAmountInFiat = nil

        guard let maxFeeNative = await yieldManagerInteractor.getMaxFeeNative() else {
            estimatedFeeState = estimatedFeeState.withFeeState(.noData)
            minimalAmountState = minimalAmountState.withFeeState(.noData)
            return
        }

        do {
            let feeParameters = try await yieldManagerInteractor.getCurrentFeeParameters()
            let estimatedFee = try await yieldManagerInteractor.getCurrentNetworkFee(feeParameters: feeParameters)
            let estimatedFeeFormatted = try await feeConverter.makeFormattedMinimalFee(from: estimatedFee)

            let minAmount = try await yieldManagerInteractor.getMinAmount(feeParameters: feeParameters)
            let minAmountFormatted = try await feeConverter.makeFormattedMinimalFee(from: minAmount)

            minimalTopupAmountInFiat = minAmount

            let maxFeeInFiat = try await feeConverter.convertToFiat(maxFeeNative, currency: .fee)
            let maxFeeFormatted = try await feeConverter.makeFormattedMaximumFee(maxFeeNative: maxFeeNative)

            let isHighFee = estimatedFee > maxFeeInFiat

            if isHighFee {
                logger.logEarningNoticeHighNetworkFeeShown()
            }

            estimatedFeeState = estimatedFeeState.withFeeState(.loaded(text: estimatedFeeFormatted.fiatFee)).withHighlighted(isHighFee)
            minimalAmountState = minimalAmountState.withFeeState(.loaded(text: minAmountFormatted.fiatFee))

            let footerBuilder = YieldInfoFooterBuilder()

            let footerText: AttributedString = if isHighFee {
                footerBuilder.buildForHighFee(
                    maxFeeFiat: maxFeeFormatted.fiatFee,
                    minFeeFiat: minAmountFormatted.fiatFee,
                    minFeeCrypto: minAmountFormatted.cryptoFee
                )
            } else {
                footerBuilder.build(
                    estimatedFeeFiat: estimatedFeeFormatted.fiatFee,
                    estimatedFeeCrypto: estimatedFeeFormatted.cryptoFee,
                    maxFeeFiat: maxFeeFormatted.fiatFee,
                    maxFeeCrypto: maxFeeFormatted.cryptoFee,
                    minFeeFiat: minAmountFormatted.fiatFee,
                    minFeeCrypto: minAmountFormatted.cryptoFee
                )
            }

            earInfoFooterText = footerText
        } catch {
            minimalAmountState = minimalAmountState.withFeeState(.noData)
            estimatedFeeState = estimatedFeeState.withFeeState(.noData)
            maxFee = nil
            earInfoFooterText = nil
        }
    }

    @MainActor
    private func fetchChartData() async {
        chartState = .loading

        do {
            try await Task.sleep(for: .seconds(0.5))
            let chartData = try await yieldManagerInteractor.getChartData()
            chartState = .loaded(chartData)
        } catch {
            chartState = .error(action: { [weak self] in
                await self?.fetchChartData()
            })
        }
    }

    @MainActor
    private func getApy() async {
        apyState = .loading
        apyTrend = .loading

        let apy = try? await yieldManagerInteractor.getApy()

        guard !Task.isCancelled else {
            return
        }

        if let apy {
            apyState = .loaded(text: PercentFormatter().format(apy, option: .earn))
            apyTrend = .increased
        } else {
            apyTrend = .none
            apyState = .noData
        }
    }

    @MainActor
    private func checkWarnings() async {
        earnInfoNotifications = []

        activityState = .active

        let isApproveRequired = await yieldManagerInteractor.getIsApproveRequired()
        let undepositedAmount = await yieldManagerInteractor.getUndepositedAmounts()

        if isApproveRequired {
            activityState = .paused
            earnInfoNotifications.append(createApproveRequiredNotification())
        }

        if let undepositedAmount = await dustFilter.filterUndepositedAmount(
            undepositedAmount,
            minimalTopupAmountInFiat: minimalTopupAmountInFiat
        ) {
            let formatted = feeConverter.formatDecimal(undepositedAmount)
            earnInfoNotifications.append(createHasUndepositedAmountsNotification(undepositedAmount: formatted))
            logger.logEarningNoticeAmountNotDepositedShown()
        }
    }
}

// MARK: - View State

extension YieldModuleActiveViewModel {
    enum ViewState: Identifiable, Equatable {
        case earnInfo
        case stopEarning
        case approve

        var id: String {
            switch self {
            case .earnInfo:
                "earnInfo"
            case .stopEarning:
                "stopEarning"
            case .approve:
                "approve"
            }
        }
    }
}

// MARK: - ActivityState

extension YieldModuleActiveViewModel {
    enum ActivityState: Equatable {
        case active
        case paused

        var description: String {
            switch self {
            case .active:
                Localization.yieldModuleStatusActive
            case .paused:
                Localization.yieldModuleStatusPaused
            }
        }
    }
}

// MARK: - ApyTrend

extension YieldModuleActiveViewModel {
    enum ApyTrend {
        case loading
        case increased
        case none
    }
}

// MARK: - Notification Builders

private extension YieldModuleActiveViewModel {
    func createApproveRequiredNotification() -> YieldModuleNotificationBannerParams {
        notificationManager.createApproveRequiredNotification { [weak self] in
            guard let self else { return }
            logger.logEarningButtonGiveApprove()
            coordinator?.openBottomSheet(viewModel: transactionFlowFactory.makeTransactionViewModel(action: .approve))
        }
    }

    func createHasUndepositedAmountsNotification(undepositedAmount: String) -> YieldModuleNotificationBannerParams {
        notificationManager.createHasUndepositedAmountsNotification(undepositedAmount: undepositedAmount)
    }
}

extension YieldModuleActiveViewModel {
    func onBonusPaidOutBannerDismiss() {
        isBonusPaidOutBannerDismissed = true
    }
}

// MARK: - Rewards Banner

private extension YieldModuleActiveViewModel {
    func makeRewardsBannerData(
        surfaceState: YieldIncentivesSurfaceState,
        summary: YieldIncentivesRewardsSummary?
    ) -> YieldModuleRewardsBannerView.ViewData? {
        guard let summary else {
            return nil
        }

        switch surfaceState {
        case .none, .apyOverlayOnly:
            return nil

        case .pendingOnly:
            return YieldModuleRewardsBannerView.ViewData(
                title: Localization.yieldModuleRewardsBannerPendingTitle,
                subtitle: Localization.yieldModuleRewardsBannerPendingSubtitle(formatPendingAmounts(summary.pendingRewards)),
                claimAvailability: .hidden
            )

        case .belowThreshold:
            return YieldModuleRewardsBannerView.ViewData(
                title: Localization.yieldModuleRewardsBannerTitle(formatClaimableTotal(summary)),
                subtitle: Localization.yieldModuleRewardsBannerBelowThresholdSubtitle,
                claimAvailability: .disabled
            )

        case .claimAvailable, .claimInFlight:
            return YieldModuleRewardsBannerView.ViewData(
                title: Localization.yieldModuleRewardsBannerTitle(formatClaimableTotal(summary)),
                subtitle: Localization.yieldModuleRewardsBannerSubtitle,
                claimAvailability: surfaceState == .claimAvailable ? .available : .disabled
            )
        }
    }

    func formatClaimableTotal(_ summary: YieldIncentivesRewardsSummary) -> String {
        // Backend USD estimates are always USD, regardless of the app's display currency.
        BalanceFormatter().formatFiatBalance(summary.totalClaimableNetUsd, currencyCode: AppConstants.usdCurrencyCode)
    }

    func formatPendingAmounts(_ rewards: [YieldIncentiveReward]) -> String {
        let formatter = BalanceFormatter()

        return rewards
            .compactMap { reward in
                guard let baseUnitsValue = Decimal(string: String(reward.pendingAmount)) else {
                    return nil
                }

                let value = baseUnitsValue / pow(10, reward.decimals)

                return formatter.formatCryptoBalance(value, currencyCode: reward.symbol)
            }
            .joined(separator: ", ")
    }
}
