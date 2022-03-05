//
//  AnimatableModifiers.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI


fileprivate func normalize(progress: Double, start: Double, end: Double) -> Double {
    let value = (progress - start) / (end - start)
    return max(0, min(value, 1))
}

struct AnimatableScaleModifier: AnimatableModifier {
    var progress: Double
    let start: Double
    let end: Double
    let curve: (Double) -> Double
    
    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(curve(normalizeProgress(progress)))
    }
    
    private func normalizeProgress(_ progress: Double) -> Double {
        normalize(progress: progress, start: start, end: end)
    }
}

struct AnimatableVisibilityModifier: AnimatableModifier {
    var progress: Double
    let start: Double
    let end: Double
    
    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }
    
    func body(content: Content) -> some View {
        content
            .opacity((start <= progress && progress < end) ? 1 : 0)
    }
}

struct AnimatableOffsetModifier: AnimatableModifier {
    var progress: Double
    let start: Double
    let end: Double
    let curveX: (Double) -> Double
    let curveY: (Double) -> Double
    
    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }
    
    func body(content: Content) -> some View {
        content
            .offset(x: curveX(normalizeProgress(progress)),
                    y: curveY(normalizeProgress(progress)))
    }
    
    private func normalizeProgress(_ progress: Double) -> Double {
        normalize(progress: progress, start: start, end: end)
    }
}

