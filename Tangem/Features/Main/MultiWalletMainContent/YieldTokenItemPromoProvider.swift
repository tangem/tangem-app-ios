//
//  YieldTokenItemPromoProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine
import TangemAssets
import TangemLocalization

final class YieldTokenItemPromoProvider {
    // MARK: - Injected

    @Injected(\.userWalletRepository)
    private var userWalletRepository: UserWalletRepository

    @Injected(\.yieldModuleNetworkManager)
    private var yieldModuleNetworkManager: YieldModuleNetworkManager

    private let yieldPromoWalletModelSubject: CurrentValueSubject<TokenItemPromoParams?, Never> = .init(nil)

    private let decimalRoundingUtility = DecimalRoundingUtility()

    private var bag = Set<AnyCancellable>()

    private let processingQueue = DispatchQueue(
        label: "com.tangem.MultiWalletMainContentViewTokenItemPromoProvider.processingQueue",
        qos: .userInitiated
    )

    // MARK: - Dependencies

    private let userWalletModel: UserWalletModel
    private let sectionsProvider: any MultiWalletMainContentViewSectionsProvider
    private let yieldModuleMarketsRepository: YieldModuleMarketsRepository
    private let tokenItemPromoBubbleVisibilityInteractor: TokenItemPromoBubbleVisibilityInteractor

    init(
        userWalletModel: UserWalletModel,
        sectionsProvider: any MultiWalletMainContentViewSectionsProvider,
        yieldModuleMarketsRepository: YieldModuleMarketsRepository,
        tokenItemPromoBubbleVisibilityInteractor: TokenItemPromoBubbleVisibilityInteractor
    ) {
        self.userWalletModel = userWalletModel
        self.sectionsProvider = sectionsProvider
        self.yieldModuleMarketsRepository = yieldModuleMarketsRepository
        self.tokenItemPromoBubbleVisibilityInteractor = tokenItemPromoBubbleVisibilityInteractor

        bind()
    }

    // MARK: - Private Implementation

    private func bind() {
        Publishers
            .CombineLatest(
                makeYieldMarketsPublisher().eraseToAnyPublisher(),
                sectionsProvider.makePlainSectionsPublisher().eraseToAnyPublisher()
            )
            .receive(on: processingQueue)
            .withWeakCaptureOf(self)
            .sink { provider, output in
                guard provider.tokenItemPromoBubbleVisibilityInteractor.shouldShowPromoBubble(for: Constants.appStorageKey) else {
                    return
                }

                let (marketInfo, sections) = output

                let thisUserWalletWalletModels = AccountsFeatureAwareWalletModelsResolver.walletModels(
                    for: provider.userWalletModel
                )

                guard !thisUserWalletWalletModels.hasActiveYield() else {
                    provider.yieldPromoWalletModelSubject.send(nil)
                    return
                }

                let yieldAvailableWalletModels = provider.walletModelWithNotActiveYield(
                    walletModels: thisUserWalletWalletModels,
                    yieldMarketInfo: marketInfo
                )

                let selectedWalletModelId = provider.selectWalletModelId(
                    from: yieldAvailableWalletModels,
                    flattenedSectionItems: sections.flatMap { $0.items }
                )

                guard let (id, contractAddress) = selectedWalletModelId,
                      let apy = marketInfo.first(where: { $0.tokenContractAddress == contractAddress })?.apy
                else {
                    return
                }

                let apyFormatted = PercentFormatter().format(apy, option: .interval)

                let params = TokenItemPromoParams(
                    walletModelId: id,
                    message: Localization.yieldModuleMainScreenPromoBannerMessage(apyFormatted),
                    icon: Assets.YieldModule.yieldLogo16.image,
                    appStorageKey: Constants.appStorageKey
                )

                provider.yieldPromoWalletModelSubject.send(params)
            }
            .store(in: &bag)
    }

    private func walletModelWithNotActiveYield(
        walletModels: [any WalletModel],
        yieldMarketInfo: [YieldModuleMarketInfo],
    ) -> [any WalletModel] {
        guard yieldMarketInfo.isNotEmpty else {
            return []
        }

        let yieldTokenAddresses = Set(yieldMarketInfo.map(\.tokenContractAddress))

        let filtered = walletModels.filter { model in
            let isNotActive = model.yieldModuleManager?.state?.state.isNotActive ?? false
            let contract = model.tokenItem.contractAddress

            guard isNotActive, let contract else { return false }
            return yieldTokenAddresses.contains(contract)
        }

        return filtered
    }

    private func selectWalletModelId(
        from filtered: [any WalletModel],
        flattenedSectionItems: [TokenItemViewModel]
    ) -> (id: WalletModelId, contractAddress: String)? {
        guard filtered.isNotEmpty else {
            return nil
        }

        var maxBalance: Decimal = .zero
        var topIds = Set<WalletModelId>()

        let roundingType = BalanceFormattingOptions.defaultFiatFormattingOptions.roundingType

        for model in filtered {
            var balance = model.fiatBalance()

            // add rounding to avoid the problem when visually identical balances
            // with different exact values lead to incorrect promo banner positioning
            if let roundingType {
                balance = decimalRoundingUtility.roundDecimal(balance, with: roundingType)
            }

            if balance > maxBalance {
                maxBalance = balance
                topIds = [model.id]
            } else if balance == maxBalance {
                topIds.insert(model.id)
            }
        }

        let selectedModel = flattenedSectionItems.first { topIds.contains($0.id) }

        guard let id = selectedModel?.id, let address = selectedModel?.tokenItem.contractAddress else {
            return nil
        }

        return (id, address)
    }

    private func makeYieldMarketsPublisher() -> any Publisher<[YieldModuleMarketInfo], Never> {
        let publisher = yieldModuleNetworkManager.marketsPublisher.filter { !$0.isEmpty }.removeDuplicates()

        guard let cachedMarkets = yieldModuleMarketsRepository.markets() else {
            return publisher
        }

        let marketsInfo = cachedMarkets.markets.map { YieldModuleMarketInfo(from: $0) }
        return publisher.prepend(marketsInfo)
    }
}

// MARK: - Constants

private enum Constants {
    static let appStorageKey = "token_item_promo_yield"
}

// MARK: - TokenItemPromoProvider

extension YieldTokenItemPromoProvider: TokenItemPromoProvider {
    var promoWalletModelPublisher: AnyPublisher<TokenItemPromoParams?, Never> {
        yieldPromoWalletModelSubject.eraseToAnyPublisher()
    }

    func hidePromoBubble() {
        tokenItemPromoBubbleVisibilityInteractor.markPromoBubbleDismissed(for: Constants.appStorageKey)
    }
}

private extension WalletModel {
    func fiatBalance() -> Decimal {
        fiatAvailableBalanceProvider.balanceType.value ?? .zero
    }
}

private extension Array where Element == any WalletModel {
    func hasActiveYield() -> Bool {
        contains { $0.yieldModuleManager?.state?.state.isEffectivelyActive ?? false }
    }
}
