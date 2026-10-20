//
//  UIImage+.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import TangemFoundation

// MARK: - App icon

extension UIImage {
    static var appIcon: UIImage? {
        guard let iconFiles: [String] = InfoDictionaryUtils.bundlePrimaryIconFiles.value(), let iconName = iconFiles.last else {
            return nil
        }

        return UIImage(named: iconName)
    }
}
