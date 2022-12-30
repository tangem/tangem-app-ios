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

            return Int("7\(response.statusCode)") ?? -7001
        case .decodingError:
            return 7601
        case .unknown(let error):
            let nsError = error as NSError
            return Int("-7\(nsError.code)") ?? -7002
        }
    }
}
