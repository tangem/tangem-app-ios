//
//  ExpressSuccessSentRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

protocol ExpressSuccessSentRoutable: AnyObject {
    func openWebView(url: URL?)
    func close()
}
