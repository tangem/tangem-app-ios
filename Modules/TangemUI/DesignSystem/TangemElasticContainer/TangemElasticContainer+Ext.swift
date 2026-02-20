//
//  TangemElasticContainer+Ext.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

public extension View {
    func onElasticContainerExpandRatioChange(perform: @escaping (CGFloat) -> Void) -> some View {
        onPreferenceChange(TangemElasticContainerStatePreference.self) { state in
            let ratio: CGFloat = switch state {
            case .some(let state): state.ratio
            case .none: 1
            }
            perform(ratio)
        }
    }
}

struct TangemElasticContainerStatePreference: PreferenceKey {
    typealias State = TangemElasticContainerState

    static var defaultValue: State?

    static func reduce(value: inout State?, nextValue: () -> State?) {}
}
