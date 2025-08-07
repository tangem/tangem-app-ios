//
//  Array+UserWalletModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//
import TangemFoundation

extension Array where Element == UserWalletModel {
    subscript(userWalletId: UserWalletId) -> UserWalletModel? {
        get {
            first(where: { $0.userWalletId == userWalletId })
        }
        set {
            if let index = firstIndex(where: { $0.userWalletId == userWalletId }) {
                if let newValue = newValue {
                    self[index] = newValue
                } else {
                    remove(at: index)
                }
            } else if let newValue = newValue {
                append(newValue)
            }
        }
    }
}
