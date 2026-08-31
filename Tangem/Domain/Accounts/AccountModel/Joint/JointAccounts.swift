//
//  JointAccounts.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

/// Unlike `CryptoAccounts`, carries no single/multiple mode of its own: whether the wallet groups its accounts
/// is the standard kind's state to tell, and no consumer treats one joint account differently from several.
typealias JointAccounts = [any JointAccountModel]
