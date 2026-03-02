//
//  ScaledSize.swift
//  TangemUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

/// A property wrapper that scales a CGSize value based on Dynamic Type settings.
@propertyWrapper
public struct ScaledSize: DynamicProperty {
    @ScaledMetric private var scaleFactor: CGFloat = 1.0
    private let baseSize: CGSize

    public init(wrappedValue: CGSize, relativeTo textStyle: Font.TextStyle = .body) {
        baseSize = wrappedValue
        _scaleFactor = ScaledMetric(wrappedValue: 1.0, relativeTo: textStyle)
    }

    public var wrappedValue: CGSize {
        CGSize(
            width: baseSize.width * scaleFactor,
            height: baseSize.height * scaleFactor
        )
    }
}
