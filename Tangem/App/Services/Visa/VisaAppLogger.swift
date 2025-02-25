//
//  VisaAppLogger.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemLogger
import TangemVisa

struct VisaAppLogger {
    private let logger: Logger

    init(tag: VisaLoggerTag) {
        logger = Logger(category: VisaLogCategory).tag(tag.rawValue)
    }

    func error<T>(_ message: @autoclosure () -> T, error: Error) {
        logger.error(message(), error: error)
    }

    func info<T>(_ message: @autoclosure () -> T) {
        logger.info(message())
    }

    func debug<T>(_ message: @autoclosure () -> T) {
        logger.debug(message())
    }
}

enum VisaLoggerTag: String {
    case walletModel = "VisaWalletModel"
    case refreshTokenRepository = "RefreshTokenRepository"
    case transactionHistoryService = "TransactionHistoryService"
    case onboardingViewModelBuilder = "OnboardingViewModelBuilder"
    case onboarding = "Onboarding"
    case cardScanHandler = "CardScanHandler"
    case customerWalletApproveTask = "CustomerWalletApproveTask"
}
