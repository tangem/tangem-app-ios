//
//  SnapshotRecordMode.swift
//  TangemSnapshotTestSupport
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import SnapshotTesting

public extension SnapshotTestingConfiguration.Record {
    static var fromEnvironment: Self {
        let environment = ProcessInfo.processInfo.environment
        if ["1", "true", "yes"].contains(environment["CI"]?.lowercased() ?? "") {
            return .never
        }
        return Self(rawValue: environment["SNAPSHOT_TESTING_RECORD"] ?? "never") ?? .never
    }
}
