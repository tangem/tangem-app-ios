//
//  TangemSdkEventLogger.swift
//  Tangem
//
//  Created by Pavel Grechikhin on 26.07.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

class TangemSdkEventLogger: TangemSdkLogger {
    func log(_ message: String, level: Log.Level) {
        if message.contains("invalidAccessCode") {
            Analytics.logAmplitude(.accessCodeIncorrect)
        }
        if message.contains("Session stopped") {
            Analytics.logAmplitude(.sessionExpired)
        }
    }
}
