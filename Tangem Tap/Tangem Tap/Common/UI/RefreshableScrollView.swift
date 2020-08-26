//
//  ActivityIndicatorView.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import SwiftUI


struct RefreshableScrollView<Content: View>: UIViewRepresentable {
    var width : CGFloat, height : CGFloat
    @Binding var refreshing: Bool
    var content: () -> Content

    init(width: CGFloat, height: CGFloat, refreshing: Binding<Bool>, @ViewBuilder content: @escaping () -> Content) {
        self.width = width
        self.height = height
        self._refreshing = refreshing
        self.content = content
    }
    
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self, refreshing: $refreshing)
    }

    
    func makeUIView(context: Context) -> UIScrollView {
        let control = UIScrollView()
        control.backgroundColor = .clear
        control.refreshControl = UIRefreshControl()
        let childView = UIHostingController(rootView: content())
        childView.view.frame = CGRect(x: 0, y: 0, width: width, height: height)
        childView.view.backgroundColor = .clear
        control.addSubview(childView.view)
        control.delegate = context.coordinator
        return control
    }
    
    func updateUIView(_ uiView: UIScrollView, context: Context) {
        if !refreshing {
            uiView.refreshControl?.endRefreshing()
        }
        uiView
    }

    class Coordinator: NSObject, UIScrollViewDelegate {
        var parent: RefreshableScrollView
         @Binding var refreshing: Bool

        init(_ parent: RefreshableScrollView, refreshing: Binding<Bool>) {
            self.parent = parent
            self._refreshing = refreshing
        }

        func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
            if let refreshing = scrollView.refreshControl?.isRefreshing, refreshing == true {
                self.refreshing = true
            }
        }
    }
}
