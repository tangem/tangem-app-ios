//
//  LoggerProviding.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

protocol LoggerProviding {
    var logger: Logger { get }
}

private struct LoggerProviderKey: InjectionKey {
    static var currentValue: LoggerProviding = LoggerProvider()
}

extension InjectedValues {
    var loggerProvider: LoggerProviding {
        get { Self[LoggerProviderKey.self] }
        set { Self[LoggerProviderKey.self] = newValue }
    }
}
