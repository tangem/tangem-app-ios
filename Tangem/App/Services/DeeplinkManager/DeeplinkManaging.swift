//
//  DeeplinkManaging.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import UIKit

public protocol DeeplinkManagerDelegate: AnyObject {
    func didReceiveDeeplink(_ manager: DeeplinkManaging, remoteRoute: RemoteRouteModel)
}

public protocol DeeplinkManaging {
    var delegate: DeeplinkManagerDelegate? { get set }

    func handleDeeplink(url: URL, options: [UIApplication.OpenURLOptionsKey: Any]) -> Bool
}

private struct DeeplinkManagingKey: InjectionKey {
    static var currentValue: DeeplinkManaging = DeeplinkManager()
}

extension InjectedValues {
    var deeplinkManager: DeeplinkManaging {
        get { Self[DeeplinkManagingKey.self] }
        set { Self[DeeplinkManagingKey.self] = newValue }
    }
}
