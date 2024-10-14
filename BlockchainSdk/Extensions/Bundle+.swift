//
//  Bundle+.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

extension Bundle {
     static var blockchainBundle: Bundle {
        let selfBundle = Bundle(for: BaseManager.self)
        if let path = selfBundle.path(forResource: "BlockchainSdk", ofType: "bundle"), //for pods
            let bundle = Bundle(path: path) {
            return bundle
        } else {
            return selfBundle
        }
    }
}
