//
//  BindableError.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI

protocol BindableError {
    var alertBinder: AlertBinder { get }
    var alertController: UIAlertController { get }
}

extension BindableError where Self: Error {
    var alertBinder: AlertBinder {
        return AlertBinder(alert: alert)
    }

    var alertController: UIAlertController {
        let vc = UIAlertController(title: Localization.commonError, message: localizedDescription, preferredStyle: .alert)
        vc.addAction(UIAlertAction(title: Localization.commonOk, style: .destructive, handler: nil))
        return vc
    }

    var alert: Alert {
        return Alert(title: Text(Localization.commonError),
                     message: Text(localizedDescription),
                     dismissButton: Alert.Button.default(Text(Localization.commonOk)))
    }
}
