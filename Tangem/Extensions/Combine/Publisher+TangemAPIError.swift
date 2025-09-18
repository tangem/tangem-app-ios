//
//  Publisher+TangemAPIError.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import Combine

extension Publisher where Failure == MoyaError {
    func mapTangemAPIError() -> Publishers.MapError<Self, TangemAPIError> {
        mapError { error in
            guard let response = error.response else {
                return TangemAPIError(code: .unknown, message: error.localizedDescription)
            }

            return TangemAPIErrorMapper.map(response: response) ?? TangemAPIError(code: .decode)
        }
    }
}
