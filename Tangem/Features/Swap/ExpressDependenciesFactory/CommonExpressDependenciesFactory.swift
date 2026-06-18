//
//  CommonExpressDependenciesFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemExpress
import TangemFoundation

class CommonExpressDependenciesFactory: ExpressDependenciesFactory {
    @Injected(\.onrampRepository)
    private var _onrampRepository: OnrampRepository

    @Injected(\.swapRepository)
    var swapRepository: any SwapRepository

    @Injected(\.expressPendingTransactionsRepository)
    var expressPendingTransactionRepository: ExpressPendingTransactionRepository

    let userWalletInfo: UserWalletInfo
    private let expressAPIProviderFactory = ExpressAPIProviderFactory()

    private(set) lazy var expressManager = makeExpressManager()
    private(set) lazy var expressAPIProvider = makeExpressAPIProvider()
    private(set) lazy var onrampRepository = makeOnrampRepository()

    init(userWalletInfo: UserWalletInfo) {
        self.userWalletInfo = userWalletInfo
    }
}

// MARK: - Private

private extension CommonExpressDependenciesFactory {
    func makeExpressManager() -> ExpressManager {
        return TangemExpressFactory().makeExpressManager(
            expressAPIProvider: expressAPIProvider,
            expressRepository: swapRepository,
            featureFlags: ExpressFeatureFlags(
                isApproveWithSwapEnabled: FeatureProvider.isAvailable(.approveFlowV2),
                isChooseBestDEXEnabled: FeatureProvider.isAvailable(.swapChooseBestDEX)
            )
        )
    }

    func makeExpressAPIProvider() -> ExpressAPIProvider {
        expressAPIProviderFactory.makeExpressAPIProvider(
            userWalletId: userWalletInfo.id,
            refcode: userWalletInfo.refcode
        )
    }

    func makeOnrampRepository() -> OnrampRepository {
        // For UI tests, use UITestOnrampRepository with predefined values
        if AppEnvironment.current.isUITest {
            return UITestOnrampRepository()
        }

        return _onrampRepository
    }
}
