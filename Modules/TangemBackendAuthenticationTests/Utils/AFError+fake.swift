//
//  AFError+fake.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct Foundation.URLError
import enum Alamofire.AFError

extension AFError {
    static let timeoutFake = AFError.sessionTaskFailed(error: URLError(.timedOut))
    static let notConnectedToInternetFake = AFError.sessionTaskFailed(error: URLError(.notConnectedToInternet))
}
