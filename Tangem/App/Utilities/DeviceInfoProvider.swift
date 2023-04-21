//
//  DeviceInfoProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import UIKit

struct DeviceInfoProvider {
    enum Subject: CaseIterable {
        case deviceModel
        case osVersion
        case appVersion

        var title: String {
            switch self {
            case .deviceModel: return "Phone model: "
            case .osVersion: return "OS version: "
            case .appVersion: return "App version: "
            }
        }

        var payload: String {
            let device = UIDevice.current
            switch self {
            case .deviceModel:
                return device.iPhoneModel?.name ?? device.model
            case .osVersion:
                return [device.systemName, device.systemVersion].joined(separator: " ")
            case .appVersion:
                return [InfoDictionaryUtils.version, InfoDictionaryUtils.bundleVersion]
                    .compactMap { $0.value() }
                    .joined(separator: " ")
            }
        }

        var description: String {
            return "\(title)\(payload)\n"
        }
    }

    static func info(for subjects: [Subject] = Subject.allCases) -> String {
        subjects.reduce(into: "\n") { $0 += $1.description }
    }
}
