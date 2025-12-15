//
//  GenericSendTokenHeaderProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemLocalization

protocol SendGenericTokenHeaderProvider {
    func makeSendTokenHeader() -> SendTokenHeader
}
