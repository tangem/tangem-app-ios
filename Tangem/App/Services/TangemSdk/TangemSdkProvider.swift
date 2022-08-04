//
//  TangemSdkProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

class TangemSdkProvider: TangemSdkProviding {
    @Injected(\.loggerProvider) var loggerProvider: LoggerProviding

    var sdk: TangemSdk = .init()

    private lazy var defaultSdkConfig: Config = {
        var config = Config()
        config.filter.allowedCardTypes = [.release, .sdk]
        config.logConfig = Log.Config.custom(logLevel: Log.Level.allCases,
                                             loggers: [loggerProvider.logger, ConsoleLogger()])
        config.filter.batchIdFilter = .deny(["0027", // todo: tangem tags
                                             "0030",
                                             "0031",
                                             "0035"])

        config.filter.issuerFilter = .deny(["TTM BANK"])
        config.allowUntrustedCards = true
        return config
    }()

    func prepareScan() {
        sdk.config = defaultSdkConfig
    }

    #if !CLIP
    func didScan(_ config: UserWalletConfig) {
        sdk.config.cardIdDisplayFormat = config.cardIdDisplayFormat
    }
    #endif
}
