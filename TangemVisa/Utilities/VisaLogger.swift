//
//  VisaLogger.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public protocol VisaLogger {
    func error(_ error: Error)
    func debug<T>(_ message: @autoclosure () -> T)
}

struct InternalLogger {
    private let logger: VisaLogger

    init(logger: VisaLogger) {
        self.logger = logger
    }

    func error(error: Error) {
        logger.error(error)
    }

    func debug<T>(subsystem: Subsystem, _ message: @autoclosure () -> T) {
        logger.debug("\(subsystem.rawValue)\(message())")
    }
}

extension InternalLogger {
    enum Subsystem: String {
        case paymentAccountInteractorBuilder = "[Visa] [PaymentAccountInteractorBuilder]: "
        case paymentAccountInteractor = "[Visa] [PaymentAccountInteractor]: "
        case apiService = "[Visa] [API Service]: "
        case tokenInfoLoader = "[Visa] [TokenInfoLoader]: "
        case authorizationTokenHandler = "[Visa] [AuthorizationTokenHandler]: "
        case activationManager = "[Visa] [ActivationManager]: "
        case cardSetupHandler = "[Visa] [CardSetupHandler]: "
        case cardActivationOrderProvider = "[Visa] [CommonCardActivationOrderProvider]: "
        case cardAuthorizationProcessor = "[Visa] [CardAuthorizationProcessor]: "
        case cardActivationTask = "[Visa] [CardActivationTask]: "
        case paymentAccountAddressProvider = "[Visa] [PaymentAccountAddressProvider]: "
        case cardAuthorizationScanHandler = "[Visa] [VisaCardAuthorizationScanHandler]: "
    }
}
