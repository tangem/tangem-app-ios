//
//  Error+.swift
//  Tangem
//
//  Created by Alexander Osokin on 20.08.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import SwiftUI

extension Error {
    var detailedError: Error {
        if case let .underlying(uError, _) = self as? MoyaError,
            case let .sessionTaskFailed(sessionError) = uError.asAFError {
            return sessionError
        }
        return self
    }
}

extension Error {
    private var alertTitle: String {
        "common_error".localized
    }
    private var okButtonTitle: String {
        "common_ok".localized
    }
    var alertBinder: AlertBinder {
        return AlertBinder(alert: alert, error: self)
    }
    
    var alert: Alert {
        return Alert(title: Text(alertTitle),
                     message: Text(self.localizedDescription),
                     dismissButton: Alert.Button.default(Text(okButtonTitle)))
    }
    
    var alertController: UIAlertController {
        let vc = UIAlertController(title: alertTitle, message: localizedDescription, preferredStyle: .alert)
        vc.addAction(UIAlertAction(title: okButtonTitle, style: .destructive, handler: nil))
        return vc
    }
}


