//
//  FloatingSheetContentWithHeader.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

public struct FloatingSheetContentWithHeader<Content: View>: View {
    private let headerConfig: HeaderConfig
    private let content: Content

    public init(
        headerConfig: HeaderConfig,
        @ViewBuilder content: () -> Content
    ) {
        self.headerConfig = headerConfig
        self.content = content()
    }

    public var body: some View {
        VStack(spacing: 0) {
            BottomSheetHeaderView(
                title: headerConfig.title,
                leading: {
                    if let backAction = headerConfig.backAction {
                        CircleButton.back(action: backAction)
                    }
                },
                trailing: {
                    if let closeAction = headerConfig.closeAction {
                        CircleButton.close(action: closeAction)
                    }
                }
            )
            .verticalPadding(8)
            .padding(.horizontal, 16)
            .padding(.top, 12)

            content
        }
    }
}

public extension FloatingSheetContentWithHeader {
    struct HeaderConfig {
        let title: String
        let backAction: (() -> Void)?
        let closeAction: (() -> Void)?

        public init(title: String, backAction: (() -> Void)?, closeAction: (() -> Void)?) {
            self.title = title
            self.backAction = backAction
            self.closeAction = closeAction
        }
    }
}
