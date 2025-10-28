//
//  SelectorReceiveAssetItemRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol SelectorReceiveAssetItemRoutable: AnyObject {
    func routeOnReceiveQR(with info: ReceiveAddressInfo)
    func copyToClipboard(with address: String)
    func share(with address: String)
}
