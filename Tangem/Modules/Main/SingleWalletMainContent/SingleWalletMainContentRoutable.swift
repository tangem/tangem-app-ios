//
//  SingleWalletMainContentRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol SingleWalletMainContentRoutable: AnyObject {
    func openMail(with dataCollector: EmailDataCollector, emailType: EmailType, recipient: String)
}
