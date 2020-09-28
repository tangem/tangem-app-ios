//
//  Error+.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
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
        } else if case let .statusCode(response) = self as? MoyaError {
            return String(data: response.data, encoding: .utf8) ?? self
        }
        return self
    }
}


struct AlertBinder: Identifiable {
    let id = UUID()
    let alert: Alert
}

extension Error {
    var alertBinder: AlertBinder {
        return AlertBinder(alert: alert)
    }
    
    var alert: Alert {
        return Alert(title: Text("common_error".localized),
                     message: Text(self.localizedDescription),
                     dismissButton: Alert.Button.default(Text("common_ok")))
    }
}
