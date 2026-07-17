//
//  AppDatabaseVersion.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// A type representing a version of the database schema.
/// - Note: Not all tables should be registered with all schema versions, e.g. when there are no changes in the table structure
/// between different versions or a table is introduced in a later version of the schema.
enum AppDatabaseVersion: CaseIterable {
    case v1
}

// MARK: - Identifiable protocol conformance

extension AppDatabaseVersion: Identifiable {
    var id: String {
        // Explicitly set identifiers to avoid accidental renaming of cases or underlying change of their raw values generation
        switch self {
        case .v1:
            return "v1"
        }
    }
}
