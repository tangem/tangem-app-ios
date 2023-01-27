//
//  TangemSkeletonModifier.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

extension View {
    @ViewBuilder
    func skeletonable(isShown: Bool, size: CGSize, radius: CGFloat = 3) -> some View {
        modifier(
            SkeletonModifier(isShown: isShown, modificationType: .size(size), radius: radius)
        )
    }
    
    @ViewBuilder
    func skeletonable(isShown: Bool, width: CGFloat, radius: CGFloat = 3) -> some View {
        modifier(
            SkeletonModifier(isShown: isShown, modificationType: .width(width), radius: radius)
        )
    }

    @ViewBuilder
    func skeletonable(isShown: Bool, radius: CGFloat = 3) -> some View {
        modifier(
            SkeletonModifier(isShown: isShown, modificationType: .overlay, radius: radius)
        )
    }
}

// MARK: Modifier for View

public struct SkeletonModifier: ViewModifier {
    private let isShown: Bool
    private let modificationType: ModificationType
    private let radius: CGFloat

    public init(isShown: Bool, modificationType: ModificationType, radius: CGFloat) {
        self.isShown = isShown
        self.modificationType = modificationType
        self.radius = radius
    }

    public func body(content: Content) -> some View {
        if isShown {
            switch modificationType {
            case .overlay:
                content
                    .overlay(
                        SkeletonView()
                            .cornerRadius(radius)
                    )
            case .size(let size):
                SkeletonView()
                    .frame(size: size)
                    .cornerRadius(radius)
            case .width(let width):
                content
                    .frame(width: width)
                    .overlay(
                        SkeletonView()
                            .cornerRadius(radius)
                    )
            }
        } else {
            content
        }
    }
}

public extension SkeletonModifier {
    enum ModificationType {
        case size(CGSize)
        case width(CGFloat)
        case overlay
    }
}
