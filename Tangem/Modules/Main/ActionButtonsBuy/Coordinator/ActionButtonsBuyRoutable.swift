//
//  ActionButtonsBuyRoutable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol ActionButtonsBuyRoutable: AnyObject {
    func openBuyCrypto(at url: URL)
    func dismiss()
}
