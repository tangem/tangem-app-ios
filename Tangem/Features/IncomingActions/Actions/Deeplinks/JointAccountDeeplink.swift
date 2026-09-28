//
//  JointAccountDeeplink.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

private typealias Shared = IncomingActionConstants.DeeplinkParams

struct JointAccountDeeplink: HostNamedDeeplink, Equatable {
    static let host = "joint_account"

    let entry: Entry
    let userWalletId: String
    let accountId: String

    var action: DeeplinkNavigationAction { .jointAccount(self) }
}

// MARK: - Types

extension JointAccountDeeplink {
    enum Entry: String {
        case members
        case overview
    }
}

// MARK: - Parsing

extension JointAccountDeeplink {
    private enum Keys {
        static let entry = "entry"
    }

    init(link: DeeplinkURL) throws {
        let query = link.query

        guard let entry = Entry(rawValue: try query.required(Keys.entry, lowercased: true)) else {
            throw DeeplinkQuery.ValidationError.malformedValue(key: Keys.entry)
        }

        self.entry = entry
        userWalletId = try query.required(Shared.userWalletId)
        accountId = try query.required(Shared.accountId, lowercased: true)
    }
}

// MARK: - Navigation

extension JointAccountDeeplink {
    @MainActor
    func findUserWalletModel() -> (any UserWalletModel)? {
        DeeplinkWalletModelLocator().findUserWalletModel(userWalletModelId: userWalletId)
    }

    @MainActor
    func findJointAccount(in userWalletModel: any UserWalletModel) async -> (any JointAccountModel)? {
        await DeeplinkWalletModelLocator().findJointAccount(withId: accountId, in: userWalletModel)
    }
}
