//
//  NetworkLoggerConfiguration+.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Moya

extension NetworkLoggerPlugin.Configuration {
    static var verboseConfiguration: NetworkLoggerPlugin.Configuration {
        let c = NetworkLoggerPlugin.Configuration(formatter: Formatter(),
                                                  output: NetworkLoggerPlugin.Configuration.defaultOutput,
                                                  logOptions: .verbose)
        return c
    }
}
