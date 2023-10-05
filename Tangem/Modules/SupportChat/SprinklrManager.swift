//
//  SprinklrManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SPRMessengerClient

final class SprinklrManager {
    @Injected(\.keysManager) private static var keysManager: KeysManager

    static func showSupportScreen() {
        let config = SPRMessengerConfig()
        config.appId = keysManager.sprinklr.appID
        config.appKey = "com.sprinklr.messenger.release"
        config.deviceId = "UNIQUE_DEVICE_ID_3" // ??
        config.environment = keysManager.sprinklr.environment
        config.skin = "MODERN"
        SPRMessenger.takeOff(config)

        guard let viewController = SPRMessengerViewController() else {
            AppLog.shared.debug("Failed to show Sprinklr screen")
            return
        }
        viewController.modalPresentationStyle = .fullScreen
        UIApplication.topViewController!.present(viewController, animated: true, completion: nil)
    }
}
