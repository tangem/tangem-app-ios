//
//  TangemSdkProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

class TangemSdkProvider: TangemSdkProviding {
    var sdk: TangemSdk = .init()

    func setup(with config: Config) {
        sdk.config = config
        // [REDACTED_TODO_COMMENT]
        config.attestationMode = .offline
    }
}
