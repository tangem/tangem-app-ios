//
//  DeeplinkParsing.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import UIKit

public protocol DeeplinkParserDelegate: AnyObject {
    func didReceiveDeeplink(_ manager: DeeplinkParsing, remoteRoute: RemoteRouteModel)
}

public protocol DeeplinkParsing {
    var delegate: DeeplinkParserDelegate? { get set }

    func handleDeeplink(url: URL, options: [UIApplication.OpenURLOptionsKey: Any]) -> Bool
}

private struct DeeplinkParsingKey: InjectionKey {
    static var currentValue: DeeplinkParsing = DeeplinkParser()
}

extension InjectedValues {
    var deeplinkParser: DeeplinkParsing {
        get { Self[DeeplinkParsingKey.self] }
        set { Self[DeeplinkParsingKey.self] = newValue }
    }
}
