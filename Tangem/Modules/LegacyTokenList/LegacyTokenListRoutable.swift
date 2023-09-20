//
//  LegacyTokenListRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

protocol LegacyTokenListRoutable: AnyObject {
    func closeModule()
    func openAddCustom(settings: LegacyManageTokensSettings, userTokensManager: UserTokensManager)
}
