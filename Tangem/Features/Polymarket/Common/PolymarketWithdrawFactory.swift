//
//  PolymarketWithdrawFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemPolymarket

struct PolymarketWithdrawFactory {
    private let services = PolymarketOnboardingServicesFactory.makeDefault()

    func makeContext(for userWalletModel: any UserWalletModel) -> PolymarketWithdrawContext {
        let walletId = userWalletModel.userWalletId.stringValue
        let signer = userWalletModel.signer
        let withdrawService = services.makeWithdrawService(walletId: walletId)
        let tracker = PolymarketWithdrawTracker(
            withdrawService: withdrawService,
            store: PolymarketWithdrawRecordStore(userWalletId: userWalletModel.userWalletId)
        )

        let transactionService = PolymarketWithdrawTransactionService(
            bridgeService: services.makeBridgeService(),
            configurationService: services.makeConfigurationService(
                walletId: walletId,
                store: InjectedValues[\.polymarketBuilderCodeStore]
            ),
            relayerService: services.makeRelayerService(),
            withdrawService: withdrawService,
            tracker: tracker,
            depositWalletResolver: PolymarketDepositWalletResolver(
                walletService: services.makeWalletService(walletId: walletId),
                ownerAddressProvider: PolymarketOnboardingFactory().makeOwnerAddressProvider(for: userWalletModel)
            ),
            signer: PolymarketBatchSigner(keysRepository: userWalletModel.keysRepository, signer: signer),
            serverClock: InjectedValues[\.polymarketServerClock]
        )

        return PolymarketWithdrawContext(
            transactionService: transactionService,
            tracker: tracker,
            signer: signer
        )
    }
}

struct PolymarketWithdrawContext {
    let transactionService: PolymarketWithdrawTransactionService
    let tracker: PolymarketWithdrawTracker
    let signer: TangemSigner

    func makeSource(
        accountModel: any PolymarketAccountModel,
        depositWalletAddress: String,
        minimumUSD: Decimal
    ) -> PolymarketWithdrawSource {
        PolymarketWithdrawSource(
            accountModel: accountModel,
            depositWalletAddress: depositWalletAddress,
            transactionService: transactionService,
            signer: signer,
            minimumUSD: minimumUSD
        )
    }
}
