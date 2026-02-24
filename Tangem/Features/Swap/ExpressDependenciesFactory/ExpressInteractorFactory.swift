//
//  ExpressInteractorFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

class ExpressInteractorFactory {
    private let userWalletInfo: UserWalletInfo
    private let initialTokenItem: TokenItem
    private let swappingPair: ExpressInteractor.SwappingPair

    private(set) lazy var expressInteractor = makeExpressInteractor()

    private let expressDependenciesFactory: ExpressDependenciesFactory

    init(input: ExpressDependenciesInput, expressDependenciesFactory: ExpressDependenciesFactory) {
        userWalletInfo = input.userWalletInfo
        initialTokenItem = input.source.tokenItem
        self.expressDependenciesFactory = expressDependenciesFactory

        swappingPair = .init(
            sender: .success(input.source),
            destination: input.destination.asExpressInteractorDestination
        )
    }

    init(input: ExpressDependenciesDestinationInput, expressDependenciesFactory: ExpressDependenciesFactory) {
        userWalletInfo = input.userWalletInfo
        initialTokenItem = input.destination.tokenItem
        self.expressDependenciesFactory = expressDependenciesFactory

        swappingPair = .init(
            sender: .loading,
            destination: .success(input.destination)
        )
    }

    func makeExpressInteractor() -> ExpressInteractor {
        ExpressInteractor(
            userWalletInfo: userWalletInfo,
            swappingPair: swappingPair,
            expressManager: expressDependenciesFactory.expressManager,
            expressPairsRepository: expressDependenciesFactory.expressPairsRepository,
            expressPendingTransactionRepository: expressDependenciesFactory.expressPendingTransactionRepository,
            expressDestinationService: expressDependenciesFactory.expressDestinationService,
            expressAPIProvider: expressDependenciesFactory.expressAPIProvider
        )
    }
}

// MARK: - ExpressDependenciesInput.PredefinedDestination+

extension ExpressDependenciesInput.PredefinedDestination {
    var asExpressInteractorDestination: ExpressInteractor.Destination? {
        switch self {
        case .none: .none
        case .loadingAndSet: .loading
        case .chosen(let wallet): .success(wallet)
        }
    }
}
