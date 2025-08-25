//
//  AppPresenter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI

/// - Note: No mutable state, so this type is considered to be `Sendable` by definition.
final class AppPresenter: @unchecked Sendable {
    static let shared = AppPresenter()

    private init() {}

    func show(_ controller: UIViewController, delay: TimeInterval = 0.3) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            UIApplication.modalFromTop(controller)
        }
    }

    @available(iOS, deprecated: 100000.0, message: "Use `AlertPresenter` as @Injected dependency instead")
    func show(_ controller: UIAlertController, delay: TimeInterval = 0.3) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            UIApplication.modalFromTop(controller)
        }
    }
}
