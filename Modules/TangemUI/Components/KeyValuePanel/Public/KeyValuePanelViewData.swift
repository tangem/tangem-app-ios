//
//  KeyValuePanelConfig.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemAssets
import SwiftUI

public struct KeyValuePanelViewData: Identifiable {
    public let id = UUID()

    let header: Header?
    let keyValues: [KeyValuePairViewData]
    let backgroundColor: Color?

    public init(
        header: Header?,
        keyValues: [KeyValuePairViewData],
        backgroundColor: Color? = Colors.Background.action
    ) {
        self.header = header
        self.keyValues = keyValues
        self.backgroundColor = backgroundColor
    }
}

public extension KeyValuePanelViewData {
    struct Header {
        let title: String
        let actionConfig: ActionConfig?

        public init(title: String, actionConfig: ActionConfig?) {
            self.title = title
            self.actionConfig = actionConfig
        }
    }
}

public extension KeyValuePanelViewData.Header {
    struct ActionConfig {
        let buttonTitle: String
        let image: ImageType?
        let action: @MainActor () -> Void

        public init(buttonTitle: String, image: ImageType?, action: @escaping () -> Void) {
            self.buttonTitle = buttonTitle
            self.image = image
            self.action = action
        }
    }
}
