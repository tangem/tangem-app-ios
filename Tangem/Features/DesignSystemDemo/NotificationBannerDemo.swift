//
//  NotificationBannerDemo.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

final class NotificationBannerDemoViewModel: ObservableObject, Identifiable {}

struct NotificationBannerDemoView: View {
    @ObservedObject var viewModel: NotificationBannerDemoViewModel

    @State
    private var stackingType: NotificaitonBannerContainerStackingType = .stack

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $stackingType) {
                Text("Stack")
                    .tag(NotificaitonBannerContainerStackingType.stack)

                Text("Carousel")
                    .tag(NotificaitonBannerContainerStackingType.carousel)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()

            NotificationBannerShowcase(stackingType: stackingType)
        }
        .navigationBarTitle(Text("NotificationBanner"))
    }
}
