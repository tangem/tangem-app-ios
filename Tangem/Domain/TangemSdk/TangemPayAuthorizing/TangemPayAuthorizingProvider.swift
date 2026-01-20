//
//  TangemPayAuthorizingProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemPay

protocol TangemPayAuthorizingProvider: AnyObject {
    var tangemPayAuthorizingInteractor: TangemPayAuthorizing { get }
}
