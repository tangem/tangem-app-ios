//
//  YieldModuleActiveViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemUI
import TangemFoundation
import TangemLocalization
import TangemAssets
import TangemSdk
import SwiftUI

final class YieldModuleActiveViewModel: ObservableObject {
    // MARK: - Injected

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
    private(set) var chartState: YieldModuleEarnInfoChartContainer.State = .loading

    @Published
    private(set) var chartKind: YieldModuleEarnInfoChartContainer.Kind = .legacy

    @Published
    private(set) var apyTrend: ApyTrend = .none

    @Published
    private(set) var rewardsBannerData: YieldModuleRewardsBannerView.ViewData?

    @Published
    private(set) var apyBreakdown: YieldApyBreakdown?

    private var incentivesSummary: YieldIncentivesRewardsSummary?
    private var hasActiveIncentiveCampaign = false
    private var hasOfferedClaimBeforeWithdrawal = false
    private var isResolvingWithdrawalClaim = false
    private var maxFee: String?

    // MARK: - Promo State

    @Published
    private(set) var promoStatus: YieldPromoStatus = .undefined

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

    // MARK: - Dependencies

    private(set) var walletModel: any WalletModel
    private weak var coordinator: YieldModuleActiveCoordinator?
    private lazy var feeConverter = YieldModuleFeeFormatter(feeCurrency: walletModel.feeTokenItem, token: walletModel.tokenItem)
    private lazy var dustFilter = YieldModuleDustFilter(feeConverter: feeConverter)

    private let transactionFlowFactory: YieldModuleTransactionFlowFactory
    private let yieldManagerInteractor: YieldManagerInteractor
    private let marketInfoPublisher: AnyPublisher<YieldModuleMarketInfo?, Never>
    private let claimInteractor: YieldIncentivesClaimInteractor?
    private let notificationManager: YieldModuleNotificationManager
    private let marketingBannerManager = MarketingBannerManager()
    private let logger: YieldAnalyticsLogger
    private let usesIncentiveDesign: Bool

    // MARK: - Properties

    private(set) var activityState: ActivityState = .active
    private(set) var readMoreURL = TangemBlogUrlBuilder().url(post: .yieldMode)
    private var minimalTopupAmountInFiat: Decimal?
    private var bag = Set<AnyCancellable>()
    private var marketStateTask: Task<Void, Never>?
    private var chartTask: Task<Void, Never>?

    // MARK: - Init

    init(
        walletModel: any WalletModel,
        coordinator: YieldModuleActiveCoordinator?,
        transactionFlowFactory: YieldModuleTransactionFlowFactory,
        yieldManagerInteractor: YieldManagerInteractor,
        marketInfoPublisher: AnyPublisher<YieldModuleMarketInfo?, Never>,
        claimInteractor: YieldIncentivesClaimInteractor?,
        notificationManager: YieldModuleNotificationManager,
        logger: YieldAnalyticsLogger,
        usesIncentiveDesign: Bool
    ) {
        self.walletModel = walletModel
        self.coordinator = coordinator
        self.transactionFlowFactory = transactionFlowFactory
        self.yieldManagerInteractor = yieldManagerInteractor
        self.marketInfoPublisher = marketInfoPublisher
        self.claimInteractor = claimInteractor
        self.logger = logger
        self.notificationManager = notificationManager
        self.usesIncentiveDesign = usesIncentiveDesign

        logger.logEarningInProgressScreenOpened()

        bind()
        start()
    }

    // MARK: - Navigation

    func onBackButtonTap() {
        coordinator?.dismiss()
    }

    func onShowStopEarningSheet() {
        guard coordinator?.isTransactionSheetPresented == false else {
            return
        }

        if YieldWithdrawalClaimBatching.isSupported(blockchain: walletModel.tokenItem.blockchain) {
            openStopEarningSheet(mayClaimRewards: true)
        } else {
            offerClaimBeforeWithdrawal()
        }
    }

    private func offerClaimBeforeWithdrawal() {
        Task { @MainActor [weak self] in
            guard let self, !isResolvingWithdrawalClaim else {
                return
            }

            isResolvingWithdrawalClaim = true
            defer { isResolvingWithdrawalClaim = false }

            let claimViewModel = await makeClaimBeforeWithdrawalViewModel()

            guard coordinator?.isClaimSheetPresented == false else {
                return
            }

            if let claimViewModel {
                hasOfferedClaimBeforeWithdrawal = true
                coordinator?.openClaimSheet(viewModel: claimViewModel)
                return
            }

            openStopEarningSheet(mayClaimRewards: false)
        }
    }

    func onPromoBonusTap() {
        coordinator?.openYieldApyBoostStory()
    }

    func onApyInfoTap() {
        guard let apyBreakdown else { return }

        coordinator?.openAboutApySheet(
            viewModel: YieldModuleAboutApyViewModel(
                baseApy: apyBreakdown.baseApy,
                rewardsApy: apyBreakdown.rewardsApy,
                usesIncentiveDesign: usesIncentiveDesign
            )
        )
    }

    func onClaimTap() {
        guard coordinator?.isClaimSheetPresented == false,
              let incentivesSummary,
              let viewModel = transactionFlowFactory.makeClaimViewModel(summary: incentivesSummary) else {
            return
        }

        coordinator?.openClaimSheet(viewModel: viewModel)
    }

    // MARK: - Public Implementation

    @MainActor
    func onPullToRefresh() async {
        await refreshIncentives(forceRefresh: true)
    }

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

        marketInfoPublisher
            .map { [usesIncentiveDesign] marketInfo -> YieldModuleEarnInfoChartContainer.Kind in
                usesIncentiveDesign && marketInfo?.incentive != nil ? .incentive : .legacy
            }
            .removeDuplicates()
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, kind in
                viewModel.reloadChart(kind: kind)
            }
            .store(in: &bag)

        claimInteractor?.claimEventPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                self?.handleClaimEvent(event)
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

        guard !Task.isCancelled else {
            return
        }

        apyBreakdown = breakdown

        await refreshIncentives()
    }

    @MainActor
    private func refreshIncentives(forceRefresh: Bool = false) async {
        hasActiveIncentiveCampaign = await yieldManagerInteractor.hasActiveIncentiveCampaign()

        guard !Task.isCancelled else {
            return
        }

        let summary: YieldIncentivesRewardsSummary?

        do {
            summary = try await yieldManagerInteractor.getIncentivesSummary(forceRefresh: forceRefresh)
        } catch {
            // A load that failed says nothing about the rewards, so the banner keeps whatever it already shows.
            AppLogger.error("Failed to load yield incentives", error: error)
            return
        }

        guard !Task.isCancelled else {
            return
        }

        incentivesSummary = summary

        await updateRewardsBanner(summary: summary)
    }

    @MainActor
    private func updateRewardsBanner(summary: YieldIncentivesRewardsSummary?) async {
        let isClaimInFlight = await claimInteractor?.isClaimInFlight ?? false
        let surfaceState = YieldIncentivesSurfaceState.make(
            campaignActive: hasActiveIncentiveCampaign,
            summary: summary,
            isClaimInFlight: isClaimInFlight
        )

        rewardsBannerData = makeRewardsBannerData(surfaceState: surfaceState, summary: summary)
    }

    private func openStopEarningSheet(mayClaimRewards: Bool) {
        coordinator?.openBottomSheet(
            viewModel: transactionFlowFactory.makeTransactionViewModel(
                action: .stop(tokenName: walletModel.tokenItem.name, mayClaimRewards: mayClaimRewards)
            )
        )
    }

    @MainActor
    private func isWithdrawalClaimAvailable() async -> Bool {
        let isClaimInFlight = await claimInteractor?.isClaimInFlight ?? false

        guard let incentivesSummary else {
            return false
        }

        let surfaceState = YieldIncentivesSurfaceState.make(
            campaignActive: hasActiveIncentiveCampaign,
            summary: incentivesSummary,
            isClaimInFlight: isClaimInFlight
        )

        return surfaceState == .claimAvailable
    }

    @MainActor
    private func makeClaimBeforeWithdrawalViewModel() async -> YieldModuleClaimViewModel? {
        guard !hasOfferedClaimBeforeWithdrawal, await isWithdrawalClaimAvailable(), let incentivesSummary else {
            return nil
        }

        return transactionFlowFactory.makeClaimViewModel(summary: incentivesSummary)
    }

    /// The claim outlives the sheet it was started from, so the screen learns about it from the tracker
    /// rather than from a callback the dismissed sheet may never get to make. Nothing reads the rewards on the
    /// way here any more, so the settled event asks for them itself.
    private func handleClaimEvent(_ event: YieldIncentivesClaimTracker.Event) {
        Task { @MainActor [weak self] in
            guard let self else { return }

            switch event {
            case .submitted:
                await updateRewardsBanner(summary: incentivesSummary)

            case .settled:
                await refreshIncentives(forceRefresh: true)
            }
        }
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

    private func reloadChart(kind: YieldModuleEarnInfoChartContainer.Kind) {
        chartTask?.cancel()
        chartKind = kind
        chartState = .loading
        chartTask = Task { @MainActor [weak self] in
            await self?.fetchChartData(kind: kind)
        }
    }

    @MainActor
    private func fetchChartData(kind: YieldModuleEarnInfoChartContainer.Kind) async {
        do {
            try await Task.sleep(for: .seconds(0.5))

            switch kind {
            case .incentive:
                let incentiveData = try await yieldManagerInteractor.getIncentiveChartData(period: .threeMonths)
                try Task.checkCancellation()
                chartState = incentiveData.baseApyData.isEmpty ? .unavailable : .incentive(incentiveData)

            case .legacy:
                let legacyData = try await yieldManagerInteractor.getChartData()
                try Task.checkCancellation()
                chartState = .legacy(legacyData)
            }
        } catch is CancellationError {
            return
        } catch {
            guard !Task.isCancelled else {
                return
            }

            chartState = .error(action: { [weak self] in
                self?.reloadChart(kind: kind)
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
}
