//
//  CardAnimSettings.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

enum AnimType: Equatable {
    case `default`
    case linear
    case easeIn
    case easeOut
    case easeInOut
    case noAnim

    func animation(with duration: Double?) -> Animation? {
        guard let duration = duration else {
            switch self {
            case .default: return .default
            case .linear: return .linear
            case .easeIn: return .easeIn
            case .easeOut: return .easeOut
            case .easeInOut: return .easeInOut
            case .noAnim: return nil
            }
        }

        switch self {
        case .default: return .default
        case .linear: return .linear(duration: duration)
        case .easeIn: return .easeIn(duration: duration)
        case .easeOut: return .easeOut(duration: duration)
        case .easeInOut: return .easeInOut(duration: duration)
        case .noAnim: return nil
        }
    }
}

struct CardAnimSettings: Equatable {
    var frame: CGSize
    var offset: CGSize
    var scale: CGFloat
    var opacity: Double
    var zIndex: Double
    var rotationAngle: Angle

    var animType: AnimType = .default
    var animDuration: Double = 0.3

    var animation: Animation? {
        animType.animation(with: animDuration)
    }

    static var zero: CardAnimSettings {
        .init(
            frame: .zero,
            offset: .zero,
            scale: 0,
            opacity: 0,
            zIndex: 0,
            rotationAngle: .zero
        )
    }
}
