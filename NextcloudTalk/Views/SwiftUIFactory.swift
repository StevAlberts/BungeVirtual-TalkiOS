//
//  SwiftUIFactory.swift
//  NextcloudTalk
//
//  Created by StevalbertS on 28/12/2021.
//

import Foundation
import SwiftUI

@available(iOS 14.0, *)
class SwiftUIViewWrapper : NSObject {

//    @objc static func createSwiftUIView(name: String) -> UIViewController {
//        return UIHostingController(rootView: MainView())
//    }
     
    @objc static func createSwiftUIView(vote: NCVote) -> UIViewController {
        return UIHostingController(rootView: MainView(vote:vote))
//        return UIHostingController(rootView: MainView())

    }
    
    @objc static func createSwiftUICommentsView() -> UIViewController {
        return UIHostingController(rootView: CommentsView())
    }

}
