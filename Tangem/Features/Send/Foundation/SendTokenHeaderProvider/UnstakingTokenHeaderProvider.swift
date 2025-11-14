//
//  UnstakingTokenHeaderProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemLocalization

struct UnstakingTokenHeaderProvider: SendGenericTokenHeaderProvider {
    func makeSendTokenHeader() -> SendTokenHeader {
        .action(name: Localization.stakingStakedAmount)
    }
}
