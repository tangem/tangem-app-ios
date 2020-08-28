//
//  ActivityIndicatorView.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import SwiftUI

struct RefreshableScrollView<Content: View>: UIViewRepresentable {
    @Binding var refreshing: Bool
    let content: () -> Content
    
    internal init(refreshing: Binding<Bool>, @ViewBuilder content: @escaping () -> Content) {
        self.content = content
        self._refreshing = refreshing
    }
    
    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.backgroundColor = .clear
        scrollView.refreshControl = UIRefreshControl()
        scrollView.delegate = context.coordinator
        updateSubview(for: scrollView)
        return scrollView
    }
    
    func updateSubview(for view: UIScrollView) {
        if let subview = view.subviews.first, !(subview is UIRefreshControl) {
            subview.removeFromSuperview()
        }
        
        let host = UIHostingController(rootView: content())
        view.addSubview(host.view)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        host.view.backgroundColor = .clear
        let constraints = [
            host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            host.view.topAnchor.constraint(equalTo: view.contentLayoutGuide.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: view.contentLayoutGuide.bottomAnchor),
            host.view.widthAnchor.constraint(equalTo: view.widthAnchor)
        ]
        view.addConstraints(constraints)
    }
    
    func updateUIView(_ uiView: UIScrollView, context: Self.Context) {
        if !refreshing {
            uiView.refreshControl?.endRefreshing()
        }
         updateSubview(for: uiView)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self, refreshing: $refreshing)
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
