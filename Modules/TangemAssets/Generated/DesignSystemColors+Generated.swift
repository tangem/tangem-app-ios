// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen
// Based on: https://github.com/SwiftGen/SwiftGen/blob/stable/Documentation/templates/xcassets/swift5.md

import SwiftUI

// MARK: - Asset Catalogs


internal enum DesignSystemColors {
    internal enum Primitives {
        internal enum Base {
            internal static let black = Color(name: "Black")
            internal static let white = Color(name: "White")
        }
        internal enum Blue {
            internal static let azure = Color(name: "Azure")
        }
        internal enum Darks {
            internal static let dark1 = Color(name: "Dark1")
            internal static let dark2 = Color(name: "Dark2")
            internal static let dark3 = Color(name: "Dark3")
            internal static let dark4 = Color(name: "Dark4")
            internal static let dark5 = Color(name: "Dark5")
            internal static let dark6 = Color(name: "Dark6")
        }
        internal enum Green {
            internal static let eucalyptus = Color(name: "Eucalyptus")
        }
        internal enum Lights {
            internal static let light1 = Color(name: "Light1")
            internal static let light2 = Color(name: "Light2")
            internal static let light3 = Color(name: "Light3")
            internal static let light4 = Color(name: "Light4")
            internal static let light5 = Color(name: "Light5")
        }
        internal enum Overlays {
            internal static let overlay1 = Color(name: "Overlay1")
            internal static let overlay2 = Color(name: "Overlay2")
        }
        internal enum Red {
            internal static let amaranth = Color(name: "Amaranth")
            internal static let flamingo = Color(name: "Flamingo")
        }
        internal enum Visa {
            internal static let background = Color(name: "background")
        }
        internal enum Yellow {
            internal static let mustard = Color(name: "Mustard")
            internal static let tangerine = Color(name: "Tangerine")
        }
    }
}

// MARK: - Implementation Details

fileprivate extension Color {
    /// Creates a named color.
    /// - Parameter name: the color resource to lookup.
    init(name: String) {
        self.init(name, bundle: .module)
    }
}

