//
//  WalletOnboardingViewRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

protocol WalletOnboardingViewRoutable: AnyObject {
    func openAccessCodeView(callback: @escaping (String) -> Void)
}
