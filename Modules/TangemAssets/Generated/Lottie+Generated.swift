// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen
// Based on: https://github.com/SwiftGen/SwiftGen/issues/627#issuecomment-715259788

import Foundation
import Lottie

// MARK: - Lottie Files Enum

public enum LottieFile {
  public static let lottieStatusScreenCheckmark = LottieAnimation.namedFromBundle("lottie_status_screen_checkmark")
  public static let lottieStatusScreenHeart = LottieAnimation.namedFromBundle("lottie_status_screen_heart")
  public static let lottieStatusScreenInfo = LottieAnimation.namedFromBundle("lottie_status_screen_info")
  public static let lottieStatusScreenPending = LottieAnimation.namedFromBundle("lottie_status_screen_pending")
  public static let lottieStatusScreenWarning = LottieAnimation.namedFromBundle("lottie_status_screen_warning")
  public static let visaOnboardingInProgress = LottieAnimation.namedFromBundle("visa_onboarding_in_progress")
}

fileprivate extension LottieAnimation {
    static func namedFromBundle(_ name: String) -> LottieAnimation {
        LottieAnimation.named(name, bundle: .module)!
    }
}

