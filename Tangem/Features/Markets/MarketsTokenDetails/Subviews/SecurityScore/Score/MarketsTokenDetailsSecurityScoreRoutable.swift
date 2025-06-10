//
//  MarketsTokenDetailsSecurityScoreRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol MarketsTokenDetailsSecurityScoreRoutable: AnyObject {
    func openSecurityScoreDetails(with providers: [MarketsTokenDetailsSecurityScore.Provider])
}
