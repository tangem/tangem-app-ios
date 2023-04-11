//
//  TangemSdkBaseFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

class TangemSdkBaseFactory {
    func makeTangemSdk(with config: Config) -> TangemSdk {
        let sdk = TangemSdk()
        sdk.config = config
        return sdk
    }
}

extension TangemSdkBaseFactory: TangemSdkFactory {
    func makeTangemSdk() -> TangemSdk {
        let config = TangemSdkConfigFactory().makeDefaultConfig()
        return makeTangemSdk(with: config)
    }
}
