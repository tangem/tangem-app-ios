//
//  UIApplication+.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import UIKit

extension UIApplication {
    func endEditing() {
        windows.first { $0.isKeyWindow }?.endEditing(true)
    }
}
