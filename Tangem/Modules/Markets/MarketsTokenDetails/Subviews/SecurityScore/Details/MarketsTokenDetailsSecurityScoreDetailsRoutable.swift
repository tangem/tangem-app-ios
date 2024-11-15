//
//  MarketsTokenDetailsSecurityScoreDetailsRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol MarketsTokenDetailsSecurityScoreDetailsRoutable: AnyObject {
    func openSecurityAudit(at url: URL, providerName: String)
}
