//
//  Config.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

public struct Config {
    /// This feature fixes NFC issues with long-running commands and security delay for iPhone 7/7+. Tangem card firmware starts from 2.39. If nil, TangemSdk will turn on this feature automatically according to iPhone model.
    public var legacyMode: Bool? = nil
    /// Enables or disables linkedTerminal feature. Default is true
    public var linkedTerminal: Bool = true
}
