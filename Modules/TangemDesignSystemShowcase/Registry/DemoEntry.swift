//
//  DemoEntry.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public import SwiftUI

@MainActor
public struct DemoEntry: Identifiable {
    public let title: String
    public let version: DSVersion?
    public let section: Section
    private let content: @MainActor () -> AnyView

    public var id: String { "\(section.title)/\(title)" }

    public init<Content: View>(
        _ title: String,
        version: DSVersion? = nil,
        section: Section,
        @ViewBuilder content: @escaping @MainActor () -> Content
    ) {
        self.title = title
        self.version = version
        self.section = section
        self.content = { AnyView(content().environment(\.dsShowcaseVersion, version)) }
    }

    public func makeView() -> AnyView {
        content()
    }
}

public extension DemoEntry {
    enum Section: CaseIterable, Sendable {
        case ds3
        case legacy

        public var title: String {
            switch self {
            case .ds3: "Design System 3"
            case .legacy: "Legacy"
            }
        }
    }
}

extension EnvironmentValues {
    @Entry var dsShowcaseVersion: DSVersion?
}
