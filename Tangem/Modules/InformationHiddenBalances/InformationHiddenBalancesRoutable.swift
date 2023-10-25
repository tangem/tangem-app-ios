//
//  InformationHiddenBalancesRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

protocol InformationHiddenBalancesRoutable: AnyObject {
    /// Pass the value `forever` as `true` to no longer show the sheet
    func dismissInformationHiddenBalances(forever: Bool)
}
