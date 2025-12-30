// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen
// Based on: https://github.com/SwiftGen/SwiftGen/issues/627#issuecomment-715259788

import Foundation
import Lottie

// MARK: - Lottie Files Enum

public enum LottieFile {
  public static let visaOnboardingInProgress = LottieAnimation.namedFromBundle("visa_onboarding_in_progress")
}

fileprivate extension LottieAnimation {
    static func namedFromBundle(_ name: String) -> LottieAnimation {
        LottieAnimation.named(name, bundle: .module)!
    }
}

