//
//  MainQRScanFlowHandler.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

struct MainQRScanFlowHandler {
    struct Context {
        let availableTokenItems: [TokenItem]
    }

    private let routeResolver: MainQRScanRouteResolver
    private let userWalletRepository: UserWalletRepository

    init(
        routeResolver: MainQRScanRouteResolver = MainQRScanRouteResolver(),
        userWalletRepository: UserWalletRepository
    ) {
        self.routeResolver = routeResolver
        self.userWalletRepository = userWalletRepository
    }

    func makeContext() -> Context {
        Context(availableTokenItems: collectAllWalletTokenItems())
    }

    func resolve(scannedCode: String, context: Context) -> MainQRScanAction {
        let availableBlockchains = context.availableTokenItems.map(\.blockchain)

        return routeResolver.resolve(
            scannedCode: scannedCode,
            availableBlockchains: availableBlockchains,
            availableTokenItems: context.availableTokenItems
        )
    }

    func resolve(scannedCode: String) -> MainQRScanAction {
        resolve(scannedCode: scannedCode, context: makeContext())
    }

    private func collectAllWalletTokenItems() -> [TokenItem] {
        var tokenItems: [TokenItem] = []
        let userWalletModels = userWalletRepository.models

        for userWalletModel in userWalletModels {
            let walletModels = AccountsFeatureAwareWalletModelsResolver.walletModels(for: userWalletModel)

            for walletModel in walletModels {
                tokenItems.append(walletModel.tokenItem)
            }
        }

        if tokenItems.isEmpty {
            MainQRScanLogger.warning(MainQRScanLoggerStrings.noWalletTokenItemsCollected)
        }

        return tokenItems
    }
}
