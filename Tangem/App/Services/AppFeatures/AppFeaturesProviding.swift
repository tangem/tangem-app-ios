//
//  AppFeaturesProviding.swift
//  Tangem
//
//  Created by Alexander Osokin on 06.05.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

protocol AppFeaturesProviding {
    var canSetAccessCode: Bool { get }
    var canSetPasscode: Bool { get }
    var canCreateTwin: Bool { get }
    var isPayIdEnabled: Bool { get }
    var canSendToPayId: Bool { get }
    var canReceiveToPayId: Bool { get }
    var canExchangeCrypto: Bool { get }
}

private struct AppFeaturesProvidingKey: InjectionKey {
    static var currentValue: AppFeaturesProviding = AppFeaturesService()
}

extension InjectedValues {
    var appFeaturesService: AppFeaturesProviding {
        get { Self[AppFeaturesProvidingKey.self] }
        set { Self[AppFeaturesProvidingKey.self] = newValue }
    }
}
