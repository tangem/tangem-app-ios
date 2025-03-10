//
//  SwapDestinationTokenAvailabilitySorter.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import TangemExpress

struct SwapDestinationTokenAvailabilitySorter {
    // MARK: - Dependencies

    @Injected(\.expressAvailabilityProvider)
    private var expressAvailabilityProvider: ExpressAvailabilityProvider

    // MARK: - Private property

    private let sourceTokenWalletModel: any WalletModel
    private let expressRepository: ExpressRepository

    init(
        sourceTokenWalletModel: any WalletModel,
        expressRepository: ExpressRepository
    ) {
        self.sourceTokenWalletModel = sourceTokenWalletModel
        self.expressRepository = expressRepository
    }
}

// MARK: - TokenAvailabilitySorter

extension SwapDestinationTokenAvailabilitySorter: TokenAvailabilitySorter {
    func sortModels(walletModels: [any WalletModel]) async -> (availableModels: [any WalletModel], unavailableModels: [any WalletModel]) {
        let availablePairs = await expressRepository.getPairs(from: sourceTokenWalletModel)

        let result = walletModels.filter { $0.id != sourceTokenWalletModel.id }.reduce(
            into: (availableModels: [any WalletModel](), unavailableModels: [any WalletModel]())
        ) { result, walletModel in
            if availablePairs.map(\.destination).contains(walletModel.expressCurrency), !walletModel.isCustom {
                result.availableModels.append(walletModel)
            } else {
                result.unavailableModels.append(walletModel)
            }
        }

        return result
    }
}
