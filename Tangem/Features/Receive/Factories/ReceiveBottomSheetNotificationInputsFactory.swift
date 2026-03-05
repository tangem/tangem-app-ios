//
//  ReceiveBottomSheetNotificationInputsFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

struct ReceiveBottomSheetNotificationInputsFactory {
    let flow: ReceiveFlow

    func makeNotificationInputs(for tokenItem: TokenItem, isYieldModuleActive: Bool = false) -> [NotificationViewInput] {
        let assetSymbol = switch flow {
        case .nft:
            Localization.detailsNftTitle
        case .crypto:
            tokenItem.currencySymbol
        }

        let baseNotificationInputs = [
            NotificationViewInput(
                style: .plain,
                severity: .info,
                settings: .init(
                    event: ReceiveNotificationEvent.irreversibleLossNotification(
                        assetSymbol: assetSymbol,
                        networkName: tokenItem.networkName
                    ),
                    dismissAction: nil
                )
            ),
        ]

        switch (isYieldModuleActive, tokenItem) {
        case (true, .token):
            return [
                NotificationViewInput(
                    style: .plain,
                    severity: .warning,
                    settings: .init(
                        event: ReceiveNotificationEvent.yieldModuleNotification(
                            tokenSymbol: tokenItem.currencySymbol,
                            tokenId: tokenItem.id
                        ),
                        dismissAction: nil
                    )
                ),
            ] + baseNotificationInputs

        default:
            break
        }

        switch (flow, tokenItem.blockchain) {
        case (.nft, .solana):
            return [
                NotificationViewInput(
                    style: .plain,
                    severity: .warning,
                    settings: .init(
                        event: ReceiveNotificationEvent.unsupportedTokenWarning(
                            title: Localization.nftReceiveUnsupportedTypes,
                            description: Localization.nftReceiveUnsupportedTypesDescription,
                            tokenItem: tokenItem
                        ),
                        dismissAction: nil
                    )
                ),
            ] + baseNotificationInputs
        case (.crypto, .solana),
             (_, .bitcoin),
             (_, .litecoin),
             (_, .stellar),
             (_, .ethereum),
             (_, .ethereumPoW),
             (_, .disChain),
             (_, .ethereumClassic),
             (_, .rsk),
             (_, .bitcoinCash),
             (_, .binance),
             (_, .cardano),
             (_, .xrp),
             (_, .ducatus),
             (_, .tezos),
             (_, .dogecoin),
             (_, .bsc),
             (_, .polygon),
             (_, .avalanche),
             (_, .fantom),
             (_, .polkadot),
             (_, .kusama),
             (_, .azero),
             (_, .tron),
             (_, .arbitrum),
             (_, .dash),
             (_, .gnosis),
             (_, .optimism),
             (_, .ton),
             (_, .kava),
             (_, .kaspa),
             (_, .ravencoin),
             (_, .cosmos),
             (_, .terraV1),
             (_, .terraV2),
             (_, .cronos),
             (_, .telos),
             (_, .octa),
             (_, .chia),
             (_, .near),
             (_, .decimal),
             (_, .veChain),
             (_, .xdc),
             (_, .algorand),
             (_, .shibarium),
             (_, .aptos),
             (_, .hedera),
             (_, .areon),
             (_, .playa3ullGames),
             (_, .pulsechain),
             (_, .aurora),
             (_, .manta),
             (_, .zkSync),
             (_, .moonbeam),
             (_, .polygonZkEVM),
             (_, .moonriver),
             (_, .mantle),
             (_, .flare),
             (_, .taraxa),
             (_, .radiant),
             (_, .base),
             (_, .joystream),
             (_, .bittensor),
             (_, .koinos),
             (_, .internetComputer),
             (_, .cyber),
             (_, .blast),
             (_, .sui),
             (_, .filecoin),
             (_, .sei),
             (_, .energyWebEVM),
             (_, .energyWebX),
             (_, .core),
             (_, .canxium),
             (_, .casper),
             (_, .chiliz),
             (_, .xodex),
             (_, .clore),
             (_, .fact0rn),
             (_, .odysseyChain),
             (_, .bitrock),
             (_, .apeChain),
             (_, .sonic),
             (_, .alephium),
             (_, .vanar),
             (_, .zkLinkNova),
             (_, .pepecoin),
             (_, .hyperliquidEVM),
             (_, .quai),
             (_, .scroll),
             (_, .linea),
             (_, .monad),
             (_, .arbitrumNova),
             (_, .plasma):
            // No additional notifications for these blockchains
            return baseNotificationInputs
        }
    }
}
