//
//  JointAccountJoinRoutable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

protocol JointAccountJoinRoutable: AnyObject {
    func closeJoin()
    func openCreatorDetails(name: String, address: String, accentColor: Color)
    func openWalletSelection(accountSelectorViewModel: AccountSelectorViewModel)
    func closeWalletSelection()
    func continueJoin(userWalletModel: any UserWalletModel)
}
