//
//  Constants.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import UIKit

enum AppConstants {
    static let tangemDomainUrl = URL(string: "https://tangem.com")!

    static var isSmallScreen: Bool {
        UIScreen.main.bounds.width < 375 || UIScreen.main.bounds.height < 650
    }

    static let messageForTokensKey = "TokensSymmetricKey"
    static let maximumFractionDigitsForBalance = 8

    static let defaultScrollViewKeyboardDismissMode = UIScrollView.KeyboardDismissMode.onDrag

    static let minusSign = "−" // shorter stick
    static let dashSign = "—" // longer stick

    static let sessionId = UUID().uuidString
}
