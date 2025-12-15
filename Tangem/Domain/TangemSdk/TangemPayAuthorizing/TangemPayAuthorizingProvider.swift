//
//  TangemPayAuthorizingProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

protocol TangemPayAuthorizingProvider: AnyObject {
    var tangemPayAuthorizingInteractor: TangemPayAuthorizing { get }
}
