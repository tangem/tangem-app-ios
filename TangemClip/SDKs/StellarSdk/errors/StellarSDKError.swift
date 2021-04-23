//
//  StellarSDKError.swift
//  stellarsdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public enum StellarSDKError: Error {
    case invalidArgument(message: String)
    case xdrDecodingError(message: String)
    case xdrEncodingError(message: String)
    case encodingError(message: String)
    case decodingError(message: String)
}
