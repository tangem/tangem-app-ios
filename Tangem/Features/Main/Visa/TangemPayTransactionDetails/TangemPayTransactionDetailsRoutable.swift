//
//  TangemPayTransactionDetailsRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol TangemPayTransactionDetailsRoutable: AnyObject {
    func transactionDetailsDidRequestClose()
    func transactionDetailsDidRequestDispute(dataCollector: EmailDataCollector, subject: VisaEmailSubject)
}
