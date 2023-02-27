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
            guard let body = error.response?.data else {
                return TangemAPIError(code: .unknown, message: error.localizedDescription)
            }

            let decoder = JSONDecoder()
            do {
                let base = try decoder.decode(TangemBaseAPIError.self, from: body)
                return base.error
            } catch {
                return TangemAPIError(code: .decode)
            }
        }
    }
}
