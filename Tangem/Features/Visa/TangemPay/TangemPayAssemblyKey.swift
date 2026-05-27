//
//  TangemPayAssemblyKey.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

private struct TangemPayAssemblyKey: InjectionKey {
    static var currentValue: TangemPayAssembly = CommonTangemPayAssembly()
}

extension InjectedValues {
    var tangemPayAssembly: TangemPayAssembly {
        get { Self[TangemPayAssemblyKey.self] }
        set { Self[TangemPayAssemblyKey.self] = newValue }
    }
}
