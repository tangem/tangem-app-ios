//
//  TangemSdkProviding.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

protocol TangemSdkProviding {
    var sdk: TangemSdk { get }

    func prepareScan()

    #if !CLIP
    func didScan(_ config: UserWalletConfig)
    #endif
}

private struct TangemSdkProviderKey: InjectionKey {
    static var currentValue: TangemSdkProviding = TangemSdkProvider()
}

extension InjectedValues {
    var tangemSdkProvider: TangemSdkProviding {
        get { Self[TangemSdkProviderKey.self] }
        set { Self[TangemSdkProviderKey.self] = newValue }
    }
}
