//
//  VerticalBar.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

// `toolbarVerticalEdge` and `axisBehavior` exist only in the iOS 27.1 SDK (SwiftUI 8.0.85). Older Xcodes fail with
// "cannot find in scope" even behind `#available`, so the SDK check has to be a compile-time one.
#if canImport(SwiftUI, _version: 8.0.85)
public extension EnvironmentValues {
    var verticalBarEdge: HorizontalEdge? {
        if #available(iOS 27.1, *) {
            return toolbarVerticalEdge
        }
        return nil
    }
}

public extension ToolbarContent {
    @ToolbarContentBuilder
    func prefersVerticalBar(_ isPreferred: Bool = true) -> some ToolbarContent {
        if #available(iOS 27.1, *) {
            axisBehavior(isPreferred ? .verticalPreferred : .automatic)
        } else {
            self
        }
    }
}

public extension CustomizableToolbarContent {
    @ToolbarContentBuilder
    func prefersVerticalBar(_ isPreferred: Bool = true) -> some CustomizableToolbarContent {
        if #available(iOS 27.1, *) {
            axisBehavior(isPreferred ? .verticalPreferred : .automatic)
        } else {
            self
        }
    }
}
#else
public extension EnvironmentValues {
    var verticalBarEdge: HorizontalEdge? { nil }
}

public extension ToolbarContent {
    func prefersVerticalBar(_ isPreferred: Bool = true) -> some ToolbarContent { self }
}

public extension CustomizableToolbarContent {
    func prefersVerticalBar(_ isPreferred: Bool = true) -> some CustomizableToolbarContent { self }
}
#endif
