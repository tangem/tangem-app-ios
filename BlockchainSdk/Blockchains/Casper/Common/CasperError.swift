//
//  CasperError.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

enum CasperError: LocalizedError {
    case undefinedDeployHash
    case unsupportedCurve
    case invalidNumber
    case none
    case invalidURL
    case invalidParams
    case parseError
    case methodNotFound
    case unknown
    case getDataBackError
    case methodCallError(code: Int, message: String, methodCall: String)
    case tooManyBytesToEncode
    case undefinedEncodeException
    case errorEmptyCurrentByte
    case errorCompareCurrentByte
    case undefinedElement

    var errorDescription: String? {
        switch self {
        case .methodCallError(let code, let message, let methodCall):
            "Method call error: \(methodCall), code: \(code), message: \(message)"
        default:
            Localization.genericErrorCode(errorCode)
        }
    }
}
