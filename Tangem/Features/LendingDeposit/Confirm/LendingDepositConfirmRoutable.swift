//
//  LendingDepositConfirmRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

@MainActor
protocol LendingDepositConfirmRoutable: AnyObject {
    func openFeeSelector()
    func openURL(_ url: URL)
    func openMail(with dataCollector: EmailDataCollector, recipient: String)
    func depositDidSend()
    func closeDeposit()
}
