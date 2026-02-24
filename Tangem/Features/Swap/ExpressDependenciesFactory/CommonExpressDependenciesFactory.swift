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

    @Injected(\.expressPairsRepository)
    var expressPairsRepository: any ExpressPairsRepository

    @Injected(\.expressPendingTransactionsRepository)
    var expressPendingTransactionRepository: ExpressPendingTransactionRepository

    private let userWalletInfo: UserWalletInfo
    private let expressAPIProviderFactory = ExpressAPIProviderFactory()

    private(set) lazy var expressManager = makeExpressManager()
    private(set) lazy var expressDestinationService = makeExpressDestinationService()
    private(set) lazy var expressAPIProvider = makeExpressAPIProvider()
    private(set) lazy var expressRepository = makeExpressRepository()
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
            expressRepository: expressRepository
        )
    }

    func makeExpressDestinationService() -> ExpressDestinationService {
        let shouldFilterForOneWallet = !FeatureProvider.isAvailable(.accounts)

        return CommonExpressDestinationService(
            userWalletId: shouldFilterForOneWallet ? userWalletInfo.id : nil
        )
    }

    func makeExpressRepository() -> ExpressRepository {
        CommonExpressRepository(expressAPIProvider: expressAPIProvider)
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
