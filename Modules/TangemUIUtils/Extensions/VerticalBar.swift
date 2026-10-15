//
//  VerticalBar.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

public extension EnvironmentValues {
    var verticalBarEdge: HorizontalEdge? {
        #if canImport(SwiftUI, _version: 8.0.85)
        if #available(iOS 27.1, *) {
            return toolbarVerticalEdge
        } else {
            return nil
        }
        #else
        return nil
        #endif // canImport(SwiftUI, _version: 8.0.85)
    }
}

public extension ToolbarContent {
    func prefersVerticalBar(_ isPreferred: Bool = true) -> some ToolbarContent {
        VerticalBarPreferringToolbarContentWrapper(isPreferred: isPreferred, content: self)
    }
}

public extension CustomizableToolbarContent {
    func prefersVerticalBar(_ isPreferred: Bool = true) -> some CustomizableToolbarContent {
        VerticalBarPreferringCustomizableToolbarContentWrapper(isPreferred: isPreferred, content: self)
    }
}

// MARK: - Auxiliary types

/// Keeps the `if #available` out of the public `prefersVerticalBar()`. With it there, `Release` builds of other modules
/// fail to link with "Undefined symbols" for SwiftUI's `buildLimitedAvailability` opaque type descriptor.
///
/// - Swift bug, remove both wrappers once it's fixed: https://github.com/swiftlang/swift/issues/92850
/// - Same failure and workaround: https://stackoverflow.com/questions/79816595/
private struct VerticalBarPreferringToolbarContentWrapper<Content: ToolbarContent>: ToolbarContent {
    let isPreferred: Bool
    let content: Content

    @ToolbarContentBuilder
    var body: some ToolbarContent {
        #if canImport(SwiftUI, _version: 8.0.85)
        if #available(iOS 27.1, *) {
            content.axisBehavior(isPreferred ? .verticalPreferred : .automatic)
        } else {
            content
        }
        #else
        content
        #endif // canImport(SwiftUI, _version: 8.0.85)
    }
}

/// Same as `VerticalBarPreferringToolbarContentWrapper` above, but for `CustomizableToolbarContent`.
private struct VerticalBarPreferringCustomizableToolbarContentWrapper<Content: CustomizableToolbarContent>: CustomizableToolbarContent {
    let isPreferred: Bool
    let content: Content

    @ToolbarContentBuilder
    var body: some CustomizableToolbarContent {
        #if canImport(SwiftUI, _version: 8.0.85)
        if #available(iOS 27.1, *) {
            content.axisBehavior(isPreferred ? .verticalPreferred : .automatic)
        } else {
            content
        }
        #else
        content
        #endif // canImport(SwiftUI, _version: 8.0.85)
    }
}
