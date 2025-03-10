//
//  WalletModel+.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

extension WalletModel {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - CustomStringConvertible protocol conformance

extension WalletModel {
    var description: String {
        TangemFoundation.objectDescription(
            self,
            userInfo: [
                "name": name,
                "isMainToken": isMainToken,
                "tokenItem": "\(tokenItem.name) (\(tokenItem.networkName))",
            ]
        )
    }
}

extension Publisher where Output == [any WalletModel] {
    func removeDuplicates() -> some Publisher<Output, Failure> {
        removeDuplicates(by: { prev, new in
            guard prev.count == new.count else {
                return false
            }

            for (prevModel, newModel) in Swift.zip(prev, new) {
                guard prevModel.id == newModel.id else {
                    return false
                }
            }

            return true
        })
    }
}
