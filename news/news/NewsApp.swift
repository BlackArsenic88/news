//
//  NewsApp.swift
//  Quartic
//
//  Created by Abraham Doe on 9/21/25.
//

import SwiftUI

@main
struct NewsApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack{
                MainTabView()
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}
