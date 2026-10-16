//
//  UITestLocalizationBundle.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum UITestLocalizationBundle {
    static let bundle: Bundle = {
        guard
            let url = Bundle(for: TestBundleToken.self).url(forResource: Constants.bundleName, withExtension: "bundle"),
            let localizationBundle = Bundle(url: url),
            let languageURL = localizationBundle.url(forResource: UITestLocale.language, withExtension: "lproj"),
            let languageBundle = Bundle(url: languageURL)
        else {
            fatalError("Unable to find \(UITestLocale.language).lproj of \(Constants.bundleName).bundle in the UI-test bundle")
        }

        return languageBundle
    }()
}

private final class TestBundleToken {}

private extension UITestLocalizationBundle {
    enum Constants {
        static let bundleName = "TangemModules_TangemLocalization"
    }
}
