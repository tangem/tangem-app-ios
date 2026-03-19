//
//  ScaledInsets.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

/// A property wrapper that scales a EdgeInsets value based on Dynamic Type settings.
@propertyWrapper
public struct ScaledInsets: DynamicProperty {
    @ScaledMetric private var scaleFactor: CGFloat = 1.0
    private let baseValue: EdgeInsets

    public init(wrappedValue: EdgeInsets, relativeTo textStyle: Font.TextStyle = .body) {
        baseValue = wrappedValue
        _scaleFactor = ScaledMetric(wrappedValue: 1.0, relativeTo: textStyle)
    }

    public var wrappedValue: EdgeInsets {
        EdgeInsets(
            top: baseValue.top * scaleFactor,
            leading: baseValue.leading * scaleFactor,
            bottom: baseValue.bottom * scaleFactor,
            trailing: baseValue.trailing * scaleFactor
        )
    }
}
