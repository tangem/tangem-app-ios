//
//  ShtorkaSurface.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine
import TangemAssets

public struct ShtorkaSurface: View {
    @State private var reportedOpacity: CGFloat?
    @Environment(\.colorScheme) private var colorScheme

    private let tintsMaterial: Bool
    private let opacity: CGFloat
    private let expansionProgress: AnyPublisher<CGFloat, Never>

    public init(tintsMaterial: Bool = false, opacity: CGFloat = 1, expansionProgress: AnyPublisher<CGFloat, Never>) {
        self.tintsMaterial = tintsMaterial
        self.opacity = opacity
        self.expansionProgress = expansionProgress
    }

    public var body: some View {
        let opacity = reportedOpacity ?? opacity
        ZStack {
            if tintsMaterial, colorScheme == .light {
                DesignSystem.Color.bgTransparentPrimary.opacity(1 - opacity)
            }

            DesignSystem.Color.bgPrimary.opacity(opacity)
        }
        // Drag updates stay in the surface; they must not invalidate the sheet's content graph.
        .onReceive(expansionProgress) { reportedOpacity = $0 }
    }
}
