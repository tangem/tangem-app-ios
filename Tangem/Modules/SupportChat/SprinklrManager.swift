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

    private static var deviceID: String {
        let id = UIDevice.current.identifierForVendor ?? UUID()
        return id.uuidString
    }

    static func showSupportScreen() {
        let config = SPRMessengerConfig()
        config.appId = keysManager.sprinklr.appID
        config.appKey = "com.sprinklr.messenger.release"
        config.deviceId = deviceID
        config.environment = keysManager.sprinklr.environment
        config.skin = "MODERN"
        SPRMessenger.takeOff(config)

        guard let viewController = SPRMessengerViewController() else {
            AppLog.shared.debug("Failed to show Sprinklr screen")
            return
        }
        viewController.modalPresentationStyle = .fullScreen // Sprinklr doesn't work as a sheet as of Oct 2023
        UIApplication.topViewController!.present(viewController, animated: true, completion: nil)
    }
}
