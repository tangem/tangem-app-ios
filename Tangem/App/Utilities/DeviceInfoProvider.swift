//
//  DeviceInfoProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import DeviceGuru

struct DeviceInfoProvider {
    
    enum Subject: CaseIterable {
        case deviceModel, osVersion, appVersion
        
        var title: String {
            switch self {
            case .deviceModel: return "Phone model: "
            case .osVersion: return "OS version: "
            case .appVersion: return "App version: "
            }
        }
        
        var description: String {
            let device = UIDevice.current
            let devGuru = DeviceGuru()
            var str = title
            switch self {
            case .deviceModel:
                str += devGuru.hardwareDescription() ?? device.model
            case .osVersion:
                str += device.systemName + " " + device.systemVersion
            case .appVersion:
                let bundle = Bundle.main
                str += (bundle.infoDictionary?["CFBundleShortVersionString"] as? String ?? "") + " (\(bundle.infoDictionary?["CFBundleVersion"] as? String ?? ""))"
            }
            str += "\n"
            return str
        }
    }
    
    static func info(for subjects: [Subject] = Subject.allCases) -> String {
        subjects.reduce(into: "\n", { $0 += $1.description })
    }
    
}
