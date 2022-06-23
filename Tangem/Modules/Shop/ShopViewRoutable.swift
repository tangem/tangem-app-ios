//
//  ShopViewRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

protocol ShopViewRoutable: AnyObject {
    func openWebCheckout(at url: URL)
    func closeWebCheckout()
}
