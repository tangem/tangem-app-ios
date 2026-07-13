//
//  AppDatabaseVersion.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum AppDatabaseVersion: CaseIterable {
    case v1
    case v2
}

// MARK: - Identifiable protocol conformance

extension AppDatabaseVersion: Identifiable {
    var id: String {
        // Explicitly set identifiers to avoid accidental renaming of cases or underlying change of their raw values generation
        switch self {
        case .v1:
            return "v1"
        case .v2:
            return "v2"
        }
    }
}
