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
    // MARK: - Dependencies

    @Injected(\.tangemSdkProvider) private var tangemSdkProvider: TangemSdkProviding

    func makeTangemSdk(with config: Config) -> TangemSdk {
        let sdk = tangemSdkProvider.sdk
        sdk.config = config
        return sdk
    }
}
