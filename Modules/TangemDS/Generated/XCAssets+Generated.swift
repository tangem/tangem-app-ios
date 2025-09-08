// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen
// Based on: https://github.com/SwiftGen/SwiftGen/blob/stable/Documentation/templates/xcassets/swift5.md

import SwiftUI

// MARK: - Asset Catalogs

public enum Colors {
      public enum Base {
        public static let black = Color(name: "Black")
        public static let white = Color(name: "White")
      }
      public enum Blue {
        public static let azure = Color(name: "Azure")
      }
      public enum Darks {
        public static let dark1 = Color(name: "Dark1")
        public static let dark2 = Color(name: "Dark2")
        public static let dark3 = Color(name: "Dark3")
        public static let dark4 = Color(name: "Dark4")
        public static let dark5 = Color(name: "Dark5")
        public static let dark6 = Color(name: "Dark6")
      }
      public enum Green {
        public static let eucalyptus = Color(name: "Eucalyptus")
      }
      public enum Lights {
        public static let light1 = Color(name: "Light1")
        public static let light2 = Color(name: "Light2")
        public static let light3 = Color(name: "Light3")
        public static let light4 = Color(name: "Light4")
        public static let light5 = Color(name: "Light5")
      }
      public enum Overlays {
        public static let overlay1 = Color(name: "Overlay1")
        public static let overlay2 = Color(name: "Overlay2")
      }
      public enum Red {
        public static let amaranth = Color(name: "Amaranth")
        public static let flamingo = Color(name: "Flamingo")
      }
      public enum Yellow {
        public static let mustard = Color(name: "Mustard")
        public static let tangerine = Color(name: "Tangerine")
      }
}
public enum Images {
      public enum Currencies {
        public static let adAndorra = ImageType(name: "ADAndorra")
        public static let aeuae = ImageType(name: "AEUAE")
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

fileprivate extension Image {
    /// Creates a named image.
    /// - Parameter name: the image resource to lookup.
    init(name: String) {
        self.init(name, bundle: .module)
    }
}

fileprivate extension UIImage {
    /// Creates a named image.
    /// - Parameter name: the image resource to lookup.
    convenience init!(name: String) {
        self.init(named: name, in: .module, compatibleWith: nil)
    }
}

#if canImport(SwiftUI)
import SwiftUI

public extension ImageType {
    var image: Image {
        Image(name: name)
    }
}
#endif

#if canImport(UIKit)
import UIKit

public extension ImageType {
    var uiImage: UIImage {
        UIImage(name: name)
    }
}
#endif
