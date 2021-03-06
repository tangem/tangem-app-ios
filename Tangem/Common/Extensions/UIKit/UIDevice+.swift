//
//  UIDevice+.swift
//  Tangem
//
//  Created by Alexander Osokin on 12.04.2022.
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
