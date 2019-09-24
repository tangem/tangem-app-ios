//
//  URISchemeErrors.swift
//  stellarsdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Errors thrown by the uri scheme
public enum URISchemeErrors {
    case invalidSignature
    case invalidOriginDomain
    case missingOriginDomain
    case missingSignature
    case originDomainSignatureMismatch
    case invalidTomlDomain
    case invalidToml
    case tomlSignatureMissing
}
