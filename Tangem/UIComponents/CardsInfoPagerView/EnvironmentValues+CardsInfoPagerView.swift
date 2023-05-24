//
// Copyright © 2023 m3g0byt3
//

import SwiftUI

// MARK: - Body vertical offset

private enum BodyViewVerticalOffsetEnvironmentKey: EnvironmentKey {
    static var defaultValue: CGFloat { Defaults.bodyViewVerticalOffset }
}

extension EnvironmentValues {
    var bodyViewVerticalOffset: CGFloat {
        get { self[BodyViewVerticalOffsetEnvironmentKey.self] }
        set { self[BodyViewVerticalOffsetEnvironmentKey.self] = newValue }
    }
}

extension View {
    func bodyViewVerticalOffset(_ offset: CGFloat) -> some View {
        environment(\.bodyViewVerticalOffset, offset)
    }
}

// MARK: - Fractional width for page switch

private enum FractionalWidthForPageSwitchEnvironmentKey: EnvironmentKey {
    static var defaultValue: CGFloat { Defaults.fractionalWidthForPageSwitch }
}

extension EnvironmentValues {
    var fractionalWidthForPageSwitch: CGFloat {
        get { self[FractionalWidthForPageSwitchEnvironmentKey.self] }
        set { self[FractionalWidthForPageSwitchEnvironmentKey.self] = clamp(newValue, min: 0.0, max: 1.0) }
    }
}

extension View {
    func fractionalWidthForPageSwitch(_ width: CGFloat) -> some View {
        environment(\.fractionalWidthForPageSwitch, width)
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
    static var bodyViewVerticalOffset: CGFloat { 44 }
    static var fractionalWidthForPageSwitch: CGFloat { 0.3 }
    static var pageSwitchAnimation: Animation { .interactiveSpring(response: 0.30) }
}
