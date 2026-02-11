//
//  DisposableEntity.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Represents a domain entity that can be disposed of, releasing any resources it holds.
/// For example, user wallet becomes disposed after removing it from the app.
protocol DisposableEntity {
    func dispose()
}
