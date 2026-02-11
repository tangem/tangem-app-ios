//
//  ExpressDependenciesFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemExpress

protocol ExpressDependenciesFactory {
    var expressInteractor: ExpressInteractor { get }
    var expressAPIProvider: ExpressAPIProvider { get }
    var expressRepository: ExpressRepository { get }

    var onrampRepository: OnrampRepository { get }
}

// MARK: - ExpressDependenciesInput

struct ExpressDependenciesInput {
    let userWalletInfo: UserWalletInfo
    let source: any ExpressInteractorSourceWallet
    let destination: PredefinedDestination

    enum PredefinedDestination {
        case none
        case loadingAndSet
        case chosen(any ExpressInteractorDestinationWallet)
    }

    init(
        userWalletInfo: UserWalletInfo,
        source: any ExpressInteractorSourceWallet,
        destination: PredefinedDestination = .none
    ) {
        self.userWalletInfo = userWalletInfo
        self.source = source
        self.destination = destination
    }
}

// MARK: - ExpressDependenciesDestinationInput

struct ExpressDependenciesDestinationInput {
    let userWalletInfo: UserWalletInfo
    let source: PredefinedSource
    let destination: any ExpressInteractorDestinationWallet

    enum PredefinedSource {
        case loadingAndSet
        case chosen(any ExpressInteractorSourceWallet)
    }

    init(
        userWalletInfo: UserWalletInfo,
        source: PredefinedSource,
        destination: any ExpressInteractorDestinationWallet
    ) {
        self.userWalletInfo = userWalletInfo
        self.source = source
        self.destination = destination
    }
}
