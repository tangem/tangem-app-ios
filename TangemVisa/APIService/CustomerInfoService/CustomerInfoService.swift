//
//  CustomerInfoService.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol CustomerInfoService {}

class CommonCustomerInfoService {
    private let authorizationTokenHandler: AuthorizationTokenHandler

    init(authorizationTokenHandler: AuthorizationTokenHandler) {
        self.authorizationTokenHandler = authorizationTokenHandler
    }
}

extension CommonCustomerInfoService: CustomerInfoService {}
