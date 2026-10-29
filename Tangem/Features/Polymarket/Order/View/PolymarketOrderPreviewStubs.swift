//
//  PolymarketOrderPreviewStubs.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemPolymarket

@MainActor
extension PolymarketOrderModel {
    static func preview(outcomeIndex: Int) -> PolymarketOrderModel {
        let market = PolymarketMarket.preview

        return PolymarketOrderModel(
            market: market,
            outcome: market.outcomes[outcomeIndex],
            eventTitle: "2026 FIFA World Cup winner",
            intent: .buy(balance: .just(output: Decimal(30000))),
            apiProvider: PolymarketOrderPreviewAPIProvider(),
            geoblockStateProvider: PolymarketOrderPreviewGeoblockStateProvider(),
            positionsService: nil,
            clobService: PolymarketOnboardingServicesFactory.makeDefault().makeCLOBService(),
            isAwaitingFundsPublisher: .just(output: false),
            collateralBalancePublisher: .just(output: Decimal(30000)),
            addFundsReadinessStream: AsyncStream { $0.yield(.preview); $0.finish() }
        )
    }
}

extension PolymarketAccountFundsInteractor.State {
    static let preview: Self = .ready(PolymarketAccountFundsInteractor.Readiness(
        depositWalletAddress: "0x1111111111111111111111111111111111111111",
        depositAvailability: .available([
            PolymarketAccountFundsInteractor.DepositTarget(
                entry: PolymarketDepositAssetCatalog.usdcOnPolygon,
                tokenItem: PolymarketUtilities.usdcTokenItem,
                minCheckoutUSD: 2,
                fundingAddress: "0x2222222222222222222222222222222222222222"
            ),
        ]),
        withdrawalAvailability: .available(minimumUSD: 2)
    ))
}

extension PolymarketMarket {
    static let preview = PolymarketMarket(
        id: "preview",
        conditionId: "0xpreview",
        title: "Will Uzbekistan win the 2026 FIFA World Cup?",
        groupItemTitle: nil,
        imageURL: nil,
        iconURL: nil,
        status: .active,
        isNegRisk: false,
        isAcceptingOrders: true,
        startDate: nil,
        endDate: nil,
        volume: 1_240_000,
        volume24h: nil,
        liquidity: nil,
        orderIndex: nil,
        outcomes: [
            PolymarketOutcome(assetId: "yes", title: "Yes", probability: 0.15),
            PolymarketOutcome(assetId: "no", title: "No", probability: 0.85),
        ]
    )
}
