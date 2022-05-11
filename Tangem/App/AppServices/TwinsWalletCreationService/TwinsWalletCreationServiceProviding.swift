//
//  TwinsWalletCreationServiceProviding.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

protocol TwinsWalletCreationServiceProviding {
    var service: TwinsWalletCreationService { get }
}

private struct TwinsWalletCreationServiceProviderKey: InjectionKey {
    static var currentValue: TwinsWalletCreationServiceProviding = TwinsWalletCreationServiceProvider()
}

extension InjectedValues {
    var coordinatorProvider: TwinsWalletCreationServiceProviding {
        get { Self[TwinsWalletCreationServiceProviderKey.self] }
        set { Self[TwinsWalletCreationServiceProviderKey.self] = newValue }
    }
}

