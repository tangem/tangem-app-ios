//
//  EarnWithdrawalResultRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol EarnWithdrawalResultRoutable: AnyObject {
    func openExplorer(url: URL)
    func openShareSheet(url: URL)
    func closeWithdrawalResult()
}
