//
//  PerformanceMonitorConfigurator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import UIKit

#if canImport(GDPerformanceView_Swift)
import GDPerformanceView_Swift
#endif // canImport(GDPerformanceView_Swift)

enum PerformanceMonitorConfigurator {
    private static var performanceMonitorStyle: PerformanceMonitor.Style {
        return .custom(
            backgroundColor: UIColor.systemBackground,
            borderColor: UIColor.label,
            borderWidth: 1.0,
            cornerRadius: 5.0,
            textColor: UIColor.label,
            font: UIFont.systemFont(ofSize: 8.0)
        )
    }

    private static var isEnabledUsingLaunchArguments: Bool {
        return UserDefaults.standard.bool(forKey: "com.tangem.PerformanceMonitorEnabled")
    }

    private static var isEnabledUsingFeatureToggle: Bool {
        return FeatureStorage().isPerformanceMonitorEnabled
    }

    static func configureIfAvailable() {
        #if canImport(GDPerformanceView_Swift)
        guard isEnabledUsingLaunchArguments || isEnabledUsingFeatureToggle else { return }

        PerformanceMonitor.shared().performanceViewConfigurator.options = [.performance, .device, .system, .memory]
        PerformanceMonitor.shared().performanceViewConfigurator.style = performanceMonitorStyle
        PerformanceMonitor.shared().start()
        #endif // canImport(GDPerformanceView_Swift)
    }
}
