//
//  FloatingSheetContentViewModel.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine

public protocol FloatingSheetContentViewModel: Identifiable {
    var id: String { get }
}

// MARK: - AnyObject default Identifiable implementation

public extension FloatingSheetContentViewModel where Self: AnyObject {
    var id: String {
        String(ObjectIdentifier(self).hashValue)
    }
}
