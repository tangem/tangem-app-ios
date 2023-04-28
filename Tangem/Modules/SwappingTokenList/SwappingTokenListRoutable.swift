//
//  SwappingTokenListRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemSwapping

protocol SwappingTokenListRoutable: AnyObject {
    func userDidTap(currency: Currency)
}
