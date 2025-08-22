//
//  ReceiveAnalyticsLogger.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol ReceiveAnalyticsLogger:
    SelectorReceiveAssetsAnalyticsLogger,
    QRCodeReceiveAssetsAnalyticsLogger,
    ItemSelectorReceiveAssetsAnalyticsLogger {}

// MARK: - ReceiveBaseView

protocol SelectorReceiveAssetsAnalyticsLogger {
    func logSelectorReceiveAssetsScreenOpened(_ hasDomainNameAddresses: Bool)
}

protocol ItemSelectorReceiveAssetsAnalyticsLogger {
    func logCopyDomainNameAddressButtonTapped()
}

protocol QRCodeReceiveAssetsAnalyticsLogger {
    func logQRCodeReceiveAssetsScreenOpened()
    func logCopyButtonTapped()
    func logShareButtonTapped()
}
