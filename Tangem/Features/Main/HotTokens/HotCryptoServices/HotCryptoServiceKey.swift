//
//  HotCryptoService+InjectionKey.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

private struct HotCryptoServiceKey: InjectionKey {
    static var currentValue: HotCryptoService = CommonHotCryptoService()
}

extension InjectedValues {
    var hotCryptoService: HotCryptoService {
        get { Self[HotCryptoServiceKey.self] }
        set { Self[HotCryptoServiceKey.self] = newValue }
    }
}
