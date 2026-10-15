//
//  PolymarketSupportChatInputFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemPolymarket

struct PolymarketSupportChatInputFactory {
    @MainActor
    func makeInput(for userWalletModel: any UserWalletModel) -> SupportChatInputModel {
        let dataCollector = PolymarketSupportDataCollector(
            accountModel: AccountModelsAggregator(.polymarket).model(from: userWalletModel.accountModelsManager),
            depositWalletAddressDerivation: makeDepositWalletAddressDerivation(for: userWalletModel),
            walletsData: SupportChatInputFactory().makeWalletsData()
        )

        return SupportChatInputModel(
            logsComposer: LogsComposer(infoProvider: dataCollector),
            userWalletId: userWalletModel.userWalletId,
            source: .polymarket
        )
    }
}

private extension PolymarketSupportChatInputFactory {
    func makeDepositWalletAddressDerivation(
        for userWalletModel: any UserWalletModel
    ) -> PolymarketSupportDataCollector.DepositWalletAddressDerivation {
        guard let ownerAddress = PolymarketOnboardingFactory().makeOwnerAddressProvider(for: userWalletModel).getOwnerAddress() else {
            return .ownerAddressUnavailable
        }

        do {
            return .derived(address: try PolymarketDepositWalletDeriver.derive(ownerAddress: ownerAddress))
        } catch {
            return .derivationFailed(error)
        }
    }
}
