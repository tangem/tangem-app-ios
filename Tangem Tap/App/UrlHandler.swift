//
//  UrlHandler.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

protocol URLHandler {
    func handle(url: URL) -> Bool
}
