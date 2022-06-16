//
//  WalletOnboardingRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

protocol WalletOnboardingRoutable: AnyObject {
    func openAccessCodeView(callback: @escaping (String) -> Void)
}
