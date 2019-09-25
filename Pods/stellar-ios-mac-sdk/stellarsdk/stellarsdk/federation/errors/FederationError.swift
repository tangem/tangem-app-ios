//
//  FederationError.swift
//  stellarsdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Errors thrown by the federation requests
public enum FederationError: Error {
    case invalidAddress
    case invalidAccountId
    case invalidDomain
    case invalidTomlDomain
    case invalidToml
    case noFederationSet
    case parsingResponseFailed(message:String)
    case horizonError(error: HorizonRequestError)
}
