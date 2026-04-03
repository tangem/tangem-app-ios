//
//  BSDKApprovePolicy+Extensions.swift
//  Tangem
//
//  Created on 10.03.2026.
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import TangemLocalization

extension BSDKApprovePolicy: @retroactive Identifiable {
    public var id: Self { self }
}

extension BSDKApprovePolicy: DefaultMenuRowViewModelAction {
    public var title: String {
        switch self {
        case .specified:
            return Localization.givePermissionCurrentTransaction
        case .unlimited:
            return Localization.givePermissionUnlimited
        }
    }
}
