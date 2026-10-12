//
//  EarnWidgetProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt
import TangemFoundation

final class EarnWidgetProvider {
    private let widgetSubject = CurrentValueSubject<FeedWidget, Never>(.startEarning(.loading))
    private let earnProvider: MarketsWidgetEarnProvider = CommonMarketsWidgetEarnService(ethereumP2PFilter: CommonEarnEthereumP2PFilter())
    private let walletModelsAggregator: WalletModelsAggregator = CommonWalletModelsAggregator(accountScope: .personal)
    private let apyResolver = EarnApyResolver()
    private let router: any EarnFeedWidgetRoutable

    private var holdings: [any WalletModel] = []
    private var featuredAPY: Decimal?
    private var hasActivePosition = false
    private var hasRequestedFeatured = false
    private var bag = Set<AnyCancellable>()
    private var holdingsBag = Set<AnyCancellable>()

    init(router: any EarnFeedWidgetRoutable) {
        self.router = router

        bind()
    }
}

// MARK: - FeedWidgetProvider

extension EarnWidgetProvider: FeedWidgetProvider {
    var widgetPublisher: AnyPublisher<FeedWidget?, Never> {
        widgetSubject
            .map(Optional.some)
            .eraseToAnyPublisher()
    }

    func refresh() {
        guard !hasRequestedFeatured || widgetSubject.value.loadingState.isFailure else {
            return
        }

        hasRequestedFeatured = true
        earnProvider.fetch()
    }

    func select() {
        if hasActivePosition {
            router.openForYou()
        } else {
            router.openEarn()
        }
    }
}

// MARK: - Private

private extension EarnWidgetProvider {
    struct Holding {
        let symbol: String
        let info: EarnApyInfo
        let balance: Decimal
        let fiatBalance: Decimal
    }

    func bind() {
        walletModelsAggregator.walletModelsPublisher
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { provider, holdings in provider.bindHoldings(holdings) }
            .store(in: &bag)

        earnProvider.earnResultPublisher
            .map { $0.value?.filter { $0.rateType == .apy }.map(\.rateValue).max() }
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { provider, featuredAPY in
                provider.featuredAPY = featuredAPY
                provider.resolveState()
            }
            .store(in: &bag)
    }

    func bindHoldings(_ holdings: [any WalletModel]) {
        self.holdings = holdings
        holdingsBag.removeAll()

        let triggers = holdings.flatMap { model -> [AnyPublisher<Void, Never>] in
            [
                model.totalTokenBalanceProvider.balanceTypePublisher.mapToVoid().eraseToAnyPublisher(),
                model.fiatTotalTokenBalanceProvider.balanceTypePublisher.mapToVoid().eraseToAnyPublisher(),
                model.stakingManager?.statePublisher.mapToVoid().eraseToAnyPublisher(),
                model.yieldModuleManager?.statePublisher.mapToVoid().eraseToAnyPublisher(),
            ].compactMap { $0 }
        }

        Publishers.MergeMany(triggers)
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { provider, _ in provider.resolveState() }
            .store(in: &holdingsBag)

        resolveState()
    }

    func resolveState() {
        let earnable = holdings.compactMap { model in
            apyResolver.resolve(for: model).map { info in
                Holding(
                    symbol: model.tokenItem.currencySymbol,
                    info: info,
                    balance: model.totalTokenBalanceProvider.balanceType.value ?? 0,
                    fiatBalance: model.fiatTotalTokenBalanceProvider.balanceType.value ?? 0
                )
            }
        }
        let best = earnable
            .filter { $0.balance > 0 && $0.info.apy > 0 }
            .max { ($0.info.apy, $0.fiatBalance) < ($1.info.apy, $1.fiatBalance) }

        hasActivePosition = earnable.contains { $0.info.isActive }

        let state: FeedEarnWidgetState? = if hasActivePosition, let best {
            FeedEarnWidgetState(maxAPY: best.info.apy, tokenSymbol: best.symbol)
        } else if let featuredAPY, featuredAPY > 0 {
            FeedEarnWidgetState(maxAPY: featuredAPY, tokenSymbol: nil)
        } else {
            nil
        }

        let result: LoadingResult<FeedEarnWidgetState, FeedWidget.LoadError> = if let state {
            .success(state)
        } else if earnProvider.earnResult.isLoading {
            .loading
        } else {
            .failure(FeedWidget.LoadError())
        }

        let widget = FeedWidget.startEarning(result)
        guard widgetSubject.value != widget else {
            return
        }

        widgetSubject.send(widget)
    }
}
