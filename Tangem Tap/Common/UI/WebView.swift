//
//  SafariView.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import SafariServices
import WebKit


struct WebViewContainer: View {
    var url: URL
    var title: LocalizedStringKey
    
    var body: some View {
        WebView(url: url)
            .navigationBarTitle(title, displayMode: .inline)
    }
}


struct WebView: UIViewRepresentable {
    var url: URL
    
    func makeUIView(context: Context) -> WKWebView {
        let view =  WKWebView()
        view.load(URLRequest(url: url))
        return view
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

//class CustomSafariViewController: UIViewController {
//    var url: URL!
//    //{
//      //  didSet {
//            // when url changes, reset the safari child view controller
//           // configureChildViewController()
//   //     }
//   // }
//
//    private var webView = WKWebView()
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        view.addSubview(webView)
//       // configureChildViewController()
//    }
//
//    override func viewWillAppear(_ animated: Bool) {
//        webView.load(URLRequest(url: url))
//    }
//
////    private func configureChildViewController() {
////        // Remove the previous safari child view controller if not nil
////        if let safariViewController = safariViewController {
////            safariViewController.willMove(toParent: self)
////            safariViewController.view.removeFromSuperview()
////            safariViewController.removeFromParent()
////            self.safariViewController = nil
////        }
////
////        // Create a new safari child view controller with the url
////        let newSafariViewController = SFSafariViewController(url: url)
////        addChild(newSafariViewController)
////        newSafariViewController.view.frame = view.frame
////        view.addSubview(newSafariViewController.view)
////        newSafariViewController.didMove(toParent: self)
////        self.safariViewController = newSafariViewController
////    }
//}
