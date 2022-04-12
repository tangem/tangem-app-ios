//
//  UIDevice+.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import UIKit

extension UIDevice {
    static var isIOS13: Bool {
        if #available(iOS 14.0, *) {
            return false
        } else {
            return true
        }
    }
}
