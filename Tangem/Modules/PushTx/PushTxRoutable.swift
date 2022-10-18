//
//  PushTxRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

protocol PushTxRoutable: AnyObject {
    func openMail(with dataCollector: EmailDataCollector, recipient: String)
    func dismiss()
}
