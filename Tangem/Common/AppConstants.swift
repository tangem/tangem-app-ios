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
    static let seedPhraseReadMoreURL = URL(string: "https://tangem.com/ru/blog/post/seed-phrase-a-risky-solution/")!

    static var isSmallScreen: Bool {
        UIScreen.main.bounds.width < 375 || UIScreen.main.bounds.height < 650
    }

    static let messageForWalletID = "UserWalletID"
    static let messageForTokensKey = "TokensSymmetricKey"
    static let maximumFractionDigitsForBalance = 8

    static let defaultScrollViewKeyboardDismissMode = UIScrollView.KeyboardDismissMode.onDrag
}
