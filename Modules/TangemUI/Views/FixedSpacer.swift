//
//  FixedSpacer.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

/// A spacer with fixed dimensions.
public struct FixedSpacer: View {
    let width: CGFloat?
    let height: CGFloat?
    let length: CGFloat?

    public init(
        width: CGFloat? = nil,
        height: CGFloat? = nil,
        length: CGFloat? = nil
    ) {
        self.width = width
        self.height = height
        self.length = length
    }

    public var body: some View {
        Spacer(minLength: length)
            .frame(width: width, height: height)
    }
}

// MARK: - Convenience extensions

public extension FixedSpacer {
    static func horizontal(_ length: CGFloat) -> Self {
        FixedSpacer(width: length, length: length)
    }

    static func vertical(_ length: CGFloat) -> Self {
        FixedSpacer(height: length, length: length)
    }
}
