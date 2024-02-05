//
//  PendingExpressTxStatusRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol PendingExpressTxStatusRoutable: AnyObject {
    func openPendingExpressTxStatus(at url: URL)
}
