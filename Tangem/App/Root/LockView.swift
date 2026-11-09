//
//  LockView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils

struct LockView: View {
    private let usesNamespace: Bool
    private var geometryEffect: GeometryEffectPropertiesModel?

    init(usesNamespace: Bool) {
        self.usesNamespace = usesNamespace
    }

    var body: some View {
        VStack(spacing: 0) {
            TangemIconView()
                .foregroundColor(DesignSystem.Color.iconPrimary)
                .padding(.bottom, 48)
                .if(usesNamespace) {
                    $0.matchedGeometryEffect(geometryEffect)
                }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.Color.bgPrimary)
        .edgesIgnoringSafeArea(.all)
    }
}

extension LockView: Setupable {
    func setGeometryEffect(_ geometryEffect: GeometryEffectPropertiesModel) -> Self {
        map { $0.geometryEffect = geometryEffect }
    }
}
