//
//  Fonts.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

enum Fonts {
    enum Regular {
        /// weight: regular, size: 34
        static var largeTitle: Font {
            if FeatureProvider.isAvailable(.dynamicFonts) {
                return DynamicFonts.largeTitle
            } else {
                return StaticFonts.largeTitle
            }
        }

        /// weight: semibold, size: 28
        static var title1: Font {
            if FeatureProvider.isAvailable(.dynamicFonts) {
                return DynamicFonts.title1
            } else {
                return StaticFonts.title1
            }
        }

        /// weight: regular, size: 22
        static var title2: Font {
            if FeatureProvider.isAvailable(.dynamicFonts) {
                return DynamicFonts.title2
            } else {
                return StaticFonts.title2
            }
        }

        /// weight: regular, size: 20
        static var title3: Font {
            if FeatureProvider.isAvailable(.dynamicFonts) {
                return DynamicFonts.title3
            } else {
                return StaticFonts.title3
            }
        }

        /// weight: semibold, size: 17
        static var headline: Font {
            if FeatureProvider.isAvailable(.dynamicFonts) {
                return DynamicFonts.headline
            } else {
                return StaticFonts.headline
            }
        }

        /// weight: regular, size: 17
        static var body: Font {
            if FeatureProvider.isAvailable(.dynamicFonts) {
                return DynamicFonts.body
            } else {
                return StaticFonts.body
            }
        }

        /// weight: regular, size: 16
        static var callout: Font {
            if FeatureProvider.isAvailable(.dynamicFonts) {
                return DynamicFonts.callout
            } else {
                return StaticFonts.callout
            }
        }

        /// weight: regular, size: 15
        static var subheadline: Font {
            if FeatureProvider.isAvailable(.dynamicFonts) {
                return DynamicFonts.subheadline
            } else {
                return StaticFonts.subheadline
            }
        }

        /// weight: regular, size: 13
        static var footnote: Font {
            if FeatureProvider.isAvailable(.dynamicFonts) {
                return DynamicFonts.footnote
            } else {
                return StaticFonts.footnote
            }
        }

        /// weight: regular, size: 12
        static var caption1: Font {
            if FeatureProvider.isAvailable(.dynamicFonts) {
                return DynamicFonts.caption1
            } else {
                return StaticFonts.caption1
            }
        }

        /// weight: regular, size: 11
        static var caption2: Font {
            if FeatureProvider.isAvailable(.dynamicFonts) {
                return DynamicFonts.caption2
            } else {
                return StaticFonts.caption2
            }
        }
    }

    enum Bold {
        /// weight: bold, size: 34
        static var largeTitle: Font {
            if FeatureProvider.isAvailable(.dynamicFonts) {
                return DynamicFonts.largeTitleBold
            } else {
                return StaticFonts.largeTitleBold
            }
        }

        /// weight: bold, size: 28
        static var title1: Font {
            if FeatureProvider.isAvailable(.dynamicFonts) {
                return DynamicFonts.title1Bold
            } else {
                return StaticFonts.title1Bold
            }
        }

        /// weight: bold, size: 22
        static var title2: Font {
            if FeatureProvider.isAvailable(.dynamicFonts) {
                return DynamicFonts.title2Bold
            } else {
                return StaticFonts.title2Bold
            }
        }

        /// weight: semibold, size: 20
        static var title3: Font {
            if FeatureProvider.isAvailable(.dynamicFonts) {
                return DynamicFonts.title3Bold
            } else {
                return StaticFonts.title3Bold
            }
        }

        /// weight: semibold, size: 17
        static var headline: Font {
            if FeatureProvider.isAvailable(.dynamicFonts) {
                return DynamicFonts.headline
            } else {
                return StaticFonts.headline
            }
        }

        /// weight: semibold, size: 17
        static var body: Font {
            if FeatureProvider.isAvailable(.dynamicFonts) {
                return DynamicFonts.bodySemibold
            } else {
                return StaticFonts.bodySemibold
            }
        }

        /// weight: medium, size: 16
        static var callout: Font {
            if FeatureProvider.isAvailable(.dynamicFonts) {
                return DynamicFonts.calloutMedium
            } else {
                return StaticFonts.calloutMedium
            }
        }

        /// weight: medium, size: 15
        static var subheadline: Font {
            if FeatureProvider.isAvailable(.dynamicFonts) {
                return DynamicFonts.subheadlineMedium
            } else {
                return StaticFonts.subheadlineMedium
            }
        }

        /// weight: semibold, size: 13
        static var footnote: Font {
            if FeatureProvider.isAvailable(.dynamicFonts) {
                return DynamicFonts.footnoteSemibold
            } else {
                return StaticFonts.footnoteSemibold
            }
        }

        /// weight: medium, size: 12
        static var caption1: Font {
            if FeatureProvider.isAvailable(.dynamicFonts) {
                return DynamicFonts.caption1Medium
            } else {
                return StaticFonts.caption1Medium
            }
        }

        /// weight: semibold, size: 11
        static var caption2: Font {
            if FeatureProvider.isAvailable(.dynamicFonts) {
                return DynamicFonts.caption2Semibold
            } else {
                return StaticFonts.caption2Semibold
            }
        }
    }
}

private enum StaticFonts {
    static let largeTitle: Font = .system(size: 34, weight: .regular)
    static let title1: Font = .system(size: 28, weight: .semibold)
    static let title2: Font = .system(size: 22, weight: .regular)
    static let title3: Font = .system(size: 20, weight: .regular)
    static let headline: Font = .system(size: 17, weight: .semibold)
    static let body: Font = .system(size: 17, weight: .regular)
    static let callout: Font = .system(size: 16, weight: .regular)
    static let subheadline: Font = .system(size: 15, weight: .regular)
    static let footnote: Font = .system(size: 13, weight: .regular)
    static let caption1: Font = .system(size: 12, weight: .regular)
    static let caption2: Font = .system(size: 11, weight: .regular)

    static let largeTitleBold: Font = .system(size: 34, weight: .bold)
    static let title1Bold: Font = .system(size: 28, weight: .bold)
    static let title2Bold: Font = .system(size: 22, weight: .bold)
    static let title3Bold: Font = .system(size: 20, weight: .semibold)
    static let headlineSemibold: Font = .system(size: 17, weight: .semibold)
    static let bodySemibold: Font = .system(size: 17, weight: .semibold)
    static let calloutMedium: Font = .system(size: 16, weight: .medium)
    static let subheadlineMedium: Font = .system(size: 15, weight: .medium)
    static let footnoteSemibold: Font = .system(size: 13, weight: .semibold)
    static let caption1Medium: Font = .system(size: 12, weight: .medium)
    static let caption2Semibold: Font = .system(size: 11, weight: .semibold)
}

private enum DynamicFonts {
    static let largeTitle: Font = .largeTitle
    static let title1: Font = .title.weight(.semibold)
    static let title2: Font = .title2
    static let title3: Font = .title3
    static let headline: Font = .headline
    static let body: Font = .body
    static let callout: Font = .callout
    static let subheadline: Font = .subheadline
    static let footnote: Font = .footnote
    static let caption1: Font = .caption
    static let caption2: Font = .caption2

    static let largeTitleBold: Font = .largeTitle.weight(.bold)
    static let title1Bold: Font = .title.weight(.bold)
    static let title2Bold: Font = .title2.weight(.bold)
    static let title3Bold: Font = .title3.weight(.bold)
    static let bodySemibold: Font = .body.weight(.semibold)
    static let calloutMedium: Font = .callout.weight(.medium)
    static let subheadlineMedium: Font = .subheadline.weight(.medium)
    static let footnoteSemibold: Font = .footnote.weight(.semibold)
    static let caption1Medium: Font = .caption.weight(.medium)
    static let caption2Semibold: Font = .caption2.weight(.semibold)
}
