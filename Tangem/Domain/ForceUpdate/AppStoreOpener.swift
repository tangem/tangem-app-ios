//
//  AppStoreOpener.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import UIKit

enum AppStoreOpener {
    static func open() {
        UIApplication.shared.open(AppConstants.appStoreURL)
    }
}
