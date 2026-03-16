//
//  TangemElasticContainerHeightRatio.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

public struct TangemElasticContainerHeightRatio: PreferenceKey {
    public static var defaultValue: CGFloat?

    public static func reduce(value: inout CGFloat?, nextValue: () -> CGFloat?) {
        value = nextValue()
    }
}
