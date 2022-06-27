//
//  SupportChatInjected.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

private struct KeysManagerKey: InjectionKey {
    static var currentValue: SupportChatService = SupportChatService()
}

extension InjectedValues {
    var supportChatService: SupportChatService {
        get { Self[KeysManagerKey.self] }
        set { Self[KeysManagerKey.self] = newValue }
    }
}
