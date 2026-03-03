//
//  Moya.Cancellable+.swift
//  TangemNetworkUtils
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import Moya

public extension Moya.Cancellable {
    func eraseToAnyCancellable() -> AnyCancellable {
        AnyCancellable(cancel)
    }
}
