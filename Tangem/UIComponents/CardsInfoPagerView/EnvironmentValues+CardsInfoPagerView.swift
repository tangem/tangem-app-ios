//
// Copyright © 2023 m3g0byt3
//

import SwiftUI

// MARK: - Body vertical offset

private enum ContentViewVerticalOffsetEnvironmentKey: EnvironmentKey {
    static var defaultValue: CGFloat { Defaults.contentViewVerticalOffset }
}

extension EnvironmentValues {
    var contentViewVerticalOffset: CGFloat {
        get { self[ContentViewVerticalOffsetEnvironmentKey.self] }
        set { self[ContentViewVerticalOffsetEnvironmentKey.self] = newValue }
    }
}

extension View {
    func contentViewVerticalOffset(_ offset: CGFloat) -> some View {
        environment(\.contentViewVerticalOffset, offset)
    }
}

// MARK: - Fractional width for page switch

private enum PageSwitchThresholdEnvironmentKey: EnvironmentKey {
    static var defaultValue: CGFloat { Defaults.pageSwitchThreshold }
}

extension EnvironmentValues {
    var pageSwitchThreshold: CGFloat {
        get { self[PageSwitchThresholdEnvironmentKey.self] }
        set { self[PageSwitchThresholdEnvironmentKey.self] = clamp(newValue, min: 0.0, max: 1.0) }
    }
}

extension View {
    func pageSwitchThreshold(_ width: CGFloat) -> some View {
        environment(\.pageSwitchThreshold, width)
    }
}

// MARK: - Page switch animation

private enum PageSwitchAnimationEnvironmentKey: EnvironmentKey {
    static var defaultValue: Animation { Defaults.pageSwitchAnimation }
}

extension EnvironmentValues {
    var pageSwitchAnimation: Animation {
        get { self[PageSwitchAnimationEnvironmentKey.self] }
        set { self[PageSwitchAnimationEnvironmentKey.self] = newValue }
    }
}

extension View {
    func pageSwitchAnimation(_ animation: Animation) -> some View {
        environment(\.pageSwitchAnimation, animation)
    }
}

// MARK: - Environment values defaults

private enum Defaults {
    static var contentViewVerticalOffset: CGFloat { 44.0 }
    static var pageSwitchThreshold: CGFloat { 0.3 }
    static var pageSwitchAnimation: Animation { .interactiveSpring(response: 0.30) }
}
