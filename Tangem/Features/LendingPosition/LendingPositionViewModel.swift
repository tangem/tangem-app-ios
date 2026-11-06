//
//  LendingPositionViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemFoundation

@MainActor
final class LendingPositionViewModel: ObservableObject {
    typealias StateModel = LendingPositionContentView.StateModel
    typealias Action = LendingPositionContentView.Action

    @Published private(set) var state: StateModel

    let calculator: EarnCalculatorViewModel

    private let tokenItem: TokenItem
    private let liquidityProvider: YieldModuleLendingLiquidityProvider
    private let apyHistoryProvider: LendingApyHistoryProvider
    private let fiatConverter: (Decimal) async -> Decimal?
    private let currencyCode: String
    private weak var router: LendingPositionRoutable?

    private var position: Decimal?
    private(set) var positionTask: Task<Void, Never>?
    private(set) var chartTask: Task<Void, Never>?

    init(
        tokenItem: TokenItem,
        currentApy: Decimal?,
        performanceFee: Decimal,
        details: EarnProductDetails,
        currencyCode: String,
        liquidityProvider: YieldModuleLendingLiquidityProvider,
        apyHistoryProvider: LendingApyHistoryProvider,
        fiatConverter: @escaping (Decimal) async -> Decimal?,
        router: LendingPositionRoutable?
    ) {
        self.tokenItem = tokenItem
        self.liquidityProvider = liquidityProvider
        self.apyHistoryProvider = apyHistoryProvider
        self.fiatConverter = fiatConverter
        self.currencyCode = currencyCode
        self.router = router

        state = StateModel(
            balance: nil,
            availableBalance: nil,
            currentApy: currentApy.map { PercentFormatter().format($0, option: .yield) } ?? BalanceFormatter.defaultEmptyBalanceString,
            isApyKnown: currentApy != nil,
            chart: .loading,
            period: .sixMonths,
            canWithdraw: false,
            details: details,
            totalBalanceInfo: Self.totalBalanceInfo(performanceFee: performanceFee),
            availableBalanceInfo: Self.availableBalanceInfo
        )
        calculator = EarnCalculatorViewModel(
            input: .default,
            incentiveApy: nil,
            projector: CompoundingEarnCalculatorProjector(apy: currentApy ?? 0, performanceFee: performanceFee),
            currencyCode: currencyCode
        )
    }

    func onAppear() {
        loadPosition()

        if chartTask == nil {
            loadChart()
        }
    }

    func handle(_ action: Action) {
        switch action {
        case .selectPeriod(let period):
            guard period != state.period else { return }
            state.period = period
            loadChart()
        case .withdraw:
            guard state.canWithdraw, let position else { return }
            router?.openWithdraw(position: position)
        case .addFunds:
            router?.openAddFunds()
        case .howItWorks:
            router?.openHowItWorks()
        case .openURL(let url):
            router?.openURL(url)
        case .close:
            router?.closeLendingPosition()
        }
    }
}

// MARK: - Funds info

// [REDACTED_TODO_COMMENT]
private extension LendingPositionViewModel {
    static func totalBalanceInfo(performanceFee: Decimal) -> EarnProductDetails.InfoSheet {
        let feePercent = PercentFormatter().format(performanceFee, option: .performanceFee)

        return EarnProductDetails.InfoSheet(
            title: "Total balance",
            content: .text("Your ETH in Aave, including the yield it has earned, after the \(feePercent) performance fee. It grows automatically while your ETH is in Aave.")
        )
    }

    static let availableBalanceInfo = EarnProductDetails.InfoSheet(
        title: "Available balance",
        content: .text("The amount you can withdraw right now. It depends on the ETH available in Aave, so it can be lower than your total balance. You can withdraw the rest once liquidity returns.")
    )
}

// MARK: - Private

private extension LendingPositionViewModel {
    func loadPosition() {
        positionTask?.cancel()
        state.canWithdraw = false
        positionTask = Task { [weak self, liquidityProvider, fiatConverter, tokenItem, currencyCode] in
            do {
                let position = try await liquidityProvider.nativePosition()
                async let available = liquidityProvider.availableToWithdraw(nativePosition: position)
                let fiat = await fiatConverter(position)
                let availableValue = (try? await available) ?? position
                let formatter = BalanceFormatter()
                guard !Task.isCancelled else { return }

                self?.position = position
                self?.state.balance = StateModel.Balance(
                    fiat: formatter.formatFiatBalance(fiat, currencyCode: currencyCode),
                    crypto: formatter.formatCryptoBalance(position, currencyCode: tokenItem.currencySymbol)
                )
                self?.state.availableBalance = formatter.formatCryptoBalance(availableValue, currencyCode: tokenItem.currencySymbol)
                self?.state.canWithdraw = position > 0
            } catch {
                guard !Task.isCancelled else { return }
                AppLogger.error(error: error)
                let empty = BalanceFormatter.defaultEmptyBalanceString
                self?.position = nil
                self?.state.balance = StateModel.Balance(fiat: empty, crypto: empty)
                self?.state.availableBalance = empty
                self?.state.canWithdraw = false
            }
        }
    }

    func loadChart() {
        chartTask?.cancel()
        state.chart = .loading

        let period = state.period
        chartTask = Task { [weak self, apyHistoryProvider] in
            do {
                let data = try await apyHistoryProvider.history(for: period)
                guard !Task.isCancelled else { return }
                self?.state.chart = .loaded(data)
            } catch {
                guard !Task.isCancelled else { return }
                AppLogger.error(error: error)
                self?.state.chart = .error { [weak self] in self?.loadChart() }
            }
        }
    }
}
