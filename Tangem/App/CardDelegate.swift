//
//  CardDelegate.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

protocol CardDelegate {
    func didScan(_ card: Card)
}
