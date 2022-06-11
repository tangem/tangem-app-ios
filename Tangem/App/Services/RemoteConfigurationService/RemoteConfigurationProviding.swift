//
//  RemoteConfigurationProviding.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

protocol RemoteConfigurationProviding {
    var warnings: [AppWarning] { get }
    var features: AppFeatures { get }
}

private struct RemoteConfigurationProviderKey: InjectionKey {
    static var currentValue: RemoteConfigurationProviding = FeaturesConfigManager()
}

extension InjectedValues {
    var remoteConfigurationProvider: RemoteConfigurationProviding {
        get { Self[RemoteConfigurationProviderKey.self] }
        set { Self[RemoteConfigurationProviderKey.self] = newValue }
    }
}
