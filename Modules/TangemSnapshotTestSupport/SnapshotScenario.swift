//
//  SnapshotScenario.swift
//  TangemSnapshotTestSupport
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SnapshotTesting
import SwiftUI
import Testing
import UIKit

public protocol SnapshotScenario: CaseIterable, Sendable, CustomTestStringConvertible {
    associatedtype Body: View
    var snapshotName: String { get }
    var canvases: [SnapshotCanvas] { get }
    var layoutDirection: LayoutDirection { get }
    var dynamicTypeSize: DynamicTypeSize { get }
    @MainActor @ViewBuilder var body: Body { get }
}

public extension SnapshotScenario {
    var canvases: [SnapshotCanvas] { [.component] }
    var layoutDirection: LayoutDirection { .leftToRight }
    var dynamicTypeSize: DynamicTypeSize { .large }
    var testDescription: String { snapshotName }
}

public extension SnapshotScenario where Self: RawRepresentable, RawValue == String {
    var snapshotName: String { rawValue }
}

@MainActor
public func assertSnapshots<S: SnapshotScenario>(
    of scenario: S,
    fileID: StaticString = #fileID,
    file filePath: StaticString = #filePath,
    line: UInt = #line,
    column: UInt = #column
) {
    let strategies = [String: Snapshotting<S.Body, UIImage>].themed(
        canvases: scenario.canvases,
        layoutDirection: scenario.layoutDirection,
        dynamicTypeSize: scenario.dynamicTypeSize
    )
    let directory = snapshotDirectory(for: filePath)

    for name in strategies.keys.sorted() {
        guard let strategy = strategies[name] else { continue }

        let failure = verifySnapshot(
            of: scenario.body,
            as: strategy,
            named: name,
            snapshotDirectory: directory,
            fileID: fileID,
            file: filePath,
            testName: scenario.snapshotName,
            line: line,
            column: column
        )

        if let failure {
            Issue.record(
                Comment(rawValue: failure),
                sourceLocation: SourceLocation(
                    fileID: "\(fileID)",
                    filePath: "\(filePath)",
                    line: Int(line),
                    column: Int(column)
                )
            )
        }
    }
}

private let snapshotTestsRoot = "TangemSnapshotTests"

private func snapshotDirectory(for filePath: StaticString) -> String? {
    let fileURL = URL(fileURLWithPath: "\(filePath)")
    let components = fileURL.pathComponents

    guard let rootIndex = components.lastIndex(of: snapshotTestsRoot) else {
        return nil
    }

    return NSString.path(withComponents: Array(components[...rootIndex]) + [
        "__Snapshots__",
        fileURL.deletingPathExtension().lastPathComponent,
    ])
}
