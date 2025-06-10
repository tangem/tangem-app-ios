//
//  ReferralError.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Moya

enum ReferralError: Error {
    case moyaError(MoyaError)
    case decodingError(DecodingError)
    case unknown(Error)

    init(_ error: Error) {
        switch error {
        case let moyaError as MoyaError:
            self = .moyaError(moyaError)
        case let decodingError as DecodingError:
            self = .decodingError(decodingError)
        default:
            self = .unknown(error)
        }
    }

    var code: Int {
        switch self {
        case .moyaError(let error):
            guard let response = error.response else {
                return 7001
            }

            return 7000 + response.statusCode
        case .decodingError:
            return 7601
        case .unknown(let error):
            let nsError = error as NSError
            // Look for status code at https://osstatus.com
            // if nothing was found - add the specific case to `ReferralError` enum
            return nsError.code
        }
    }
}
