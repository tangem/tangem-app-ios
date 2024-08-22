//
//  BottomScrollableSheetGrabberView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

extension View {
    func bottomScrollableSheetGrabber() -> some View {
        overlay(alignment: .top) {
            GrabberViewFactory()
                .makeSwiftUIView()
        }
    }
}
