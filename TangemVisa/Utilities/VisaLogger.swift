//
//  InternalLogger.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemLogger

public let VisaLogCategory = OSLogCategory(name: "Visa")

struct InternalLogger {
    private let logger: Logger

    init(tag: Tag) {
        logger = Logger(category: VisaLogCategory).tag(tag.rawValue)
    }

    func error<T>(_ message: @autoclosure () -> T, error: Error) {
        logger.error(message(), error: error)
    }

    func info<T>(_ message: @autoclosure () -> T) {
        logger.info(message())
    }
}

extension InternalLogger {
    enum Tag: String {
        case paymentAccountInteractorBuilder = "PaymentAccountInteractorBuilder"
        case paymentAccountInteractor = "PaymentAccountInteractor"
        case apiService = "API Service"
        case tokenInfoLoader = "TokenInfoLoader"
        case authorizationTokenHandler = "AuthorizationTokenHandler"
        case activationManager = "ActivationManager"
        case cardSetupHandler = "CardSetupHandler"
        case cardActivationOrderProvider = "CommonCardActivationOrderProvider"
        case cardAuthorizationProcessor = "CardAuthorizationProcessor"
        case cardActivationTask = "CardActivationTask"
        case paymentAccountAddressProvider = "PaymentAccountAddressProvider"
        case cardAuthorizationScanHandler = "VisaCardAuthorizationScanHandler"
    }
}
