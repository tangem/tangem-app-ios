//
//  SaltPayTangemSdkFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

class SaltPayTangemSdkFactory: TangemSdkFactory {
    private let isAccessCodeSet: Bool

    init(isAccessCodeSet: Bool) {
        self.isAccessCodeSet = isAccessCodeSet
    }

    func makeTangemSdk() -> TangemSdk {
        var config = TangemSdkConfigFactory().makeDefaultConfig()
        config.cardIdDisplayFormat = .none
        config.accessCodeRequestPolicy = AccessCodeRequestPolicyFactory().makePolicy(isAccessCodeSet: isAccessCodeSet)
        let sdk = TangemSdkDefaultFactory().makeTangemSdk(with: config)
        return sdk
    }
}
