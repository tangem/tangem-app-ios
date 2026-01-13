//
//  YieldTokenItemPromoProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemAssets
import TangemLocalization

final class YieldTokenItemPromoProvider {
    // MARK: - Injected

    @Injected(\.userWalletRepository)
    private var userWalletRepository: UserWalletRepository

    @Injected(\.yieldModuleNetworkManager)
    private var yieldModuleNetworkManager: YieldModuleNetworkManager

    private let decimalRoundingUtility = DecimalRoundingUtility()

    private let processingQueue = DispatchQueue(
        label: "com.tangem.MultiWalletMainContentViewTokenItemPromoProvider.processingQueue",
        qos: .userInitiated
    )

    // MARK: - Dependencies

    private let userWalletModel: UserWalletModel
    private let yieldModuleMarketsRepository: YieldModuleMarketsRepository
    private let tokenItemPromoBubbleVisibilityInteractor: TokenItemPromoBubbleVisibilityInteractor

    init(
        userWalletModel: UserWalletModel,
        yieldModuleMarketsRepository: YieldModuleMarketsRepository,
        tokenItemPromoBubbleVisibilityInteractor: TokenItemPromoBubbleVisibilityInteractor
    ) {
        self.userWalletModel = userWalletModel
        self.yieldModuleMarketsRepository = yieldModuleMarketsRepository
        self.tokenItemPromoBubbleVisibilityInteractor = tokenItemPromoBubbleVisibilityInteractor
    }

    // MARK: - Private Implementation

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
        promoProviderInput: [TokenItemPromoProviderInput]
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

        let selectedModel = promoProviderInput.first { topIds.contains($0.id) }

        guard let id = selectedModel?.id, let address = selectedModel?.tokenItem.contractAddress else {
            return nil
        }

        return (id, address)
    }

    private func makeYieldMarketsPublisher() -> some Publisher<[YieldModuleMarketInfo], Never> {
        let publisher = yieldModuleNetworkManager
            .marketsPublisher
            .filter { !$0.isEmpty }
            .removeDuplicates()
            .eraseToAnyPublisher()

        guard let cachedMarkets = yieldModuleMarketsRepository.markets() else {
            return publisher
        }

        let marketsInfo = cachedMarkets.markets.map { YieldModuleMarketInfo(from: $0) }

        return publisher
            .prepend(marketsInfo)
            .eraseToAnyPublisher()
    }
}

// MARK: - Constants

private enum Constants {
    static let appStorageKey = "token_item_promo_yield"
}

// MARK: - TokenItemPromoProvider

extension YieldTokenItemPromoProvider: TokenItemPromoProvider {
    func makePromoOutputPublisher(
        using promoInputPublisher: some Publisher<[TokenItemPromoProviderInput], Never>
    ) -> AnyPublisher<TokenItemPromoProviderOutput?, Never> {
        return makeYieldMarketsPublisher()
            .combineLatest(promoInputPublisher)
            .receive(on: processingQueue)
            .withWeakCaptureOf(self)
            .map { provider, output -> TokenItemPromoProviderOutput? in
                guard provider.tokenItemPromoBubbleVisibilityInteractor.shouldShowPromoBubble(for: Constants.appStorageKey) else {
                    return nil
                }

                let (marketInfo, promoProviderInput) = output

                let thisUserWalletWalletModels = AccountsFeatureAwareWalletModelsResolver.walletModels(
                    for: provider.userWalletModel
                )

                guard !thisUserWalletWalletModels.hasActiveYield() else {
                    return nil
                }

                let yieldAvailableWalletModels = provider.walletModelWithNotActiveYield(
                    walletModels: thisUserWalletWalletModels,
                    yieldMarketInfo: marketInfo
                )

                let selectedWalletModelId = provider.selectWalletModelId(
                    from: yieldAvailableWalletModels,
                    promoProviderInput: promoProviderInput
                )

                guard
                    let (id, contractAddress) = selectedWalletModelId,
                    let apy = marketInfo.first(where: { $0.tokenContractAddress == contractAddress })?.apy
                else {
                    return nil
                }

                let apyFormatted = PercentFormatter().format(apy, option: .interval)

                return TokenItemPromoProviderOutput(
                    walletModelId: id,
                    message: Localization.yieldModuleMainScreenPromoBannerMessage(apyFormatted),
                    icon: Assets.YieldModule.yieldLogo16.image,
                    appStorageKey: Constants.appStorageKey
                )
            }
            .eraseToAnyPublisher()
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
