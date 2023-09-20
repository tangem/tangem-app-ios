//
//  UITraitCollection+.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import UIKit

extension UITraitCollection {
    static var isDarkMode: Bool {
        UITraitCollection.current.userInterfaceStyle == .dark
    }
}
