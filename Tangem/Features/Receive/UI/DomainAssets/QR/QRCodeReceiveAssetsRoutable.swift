//
//  QRCodeReceiveAssetsRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol QRCodeReceiveAssetsRoutable: AnyObject {
    func copyToClipboard(with address: String)
    func share(with address: String)
}
