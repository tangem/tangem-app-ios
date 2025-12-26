//
//  HotCryptoAddTokenRoutable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol HotCryptoAddTokenRoutable: AnyObject {
    func close()
    func presentSuccessToast(with text: String)
    func presentErrorToast(with text: String)
    func openOnramp(input: SendInput, parameters: PredefinedOnrampParameters)
}
