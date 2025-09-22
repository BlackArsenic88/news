//
//  MainTabView.swift
//  Quartic
//
//  Created by Abraham Doe on 4/24/25.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            NewsView()
                   .tabItem { Label("Home", systemImage: "house") }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Beta")
                    .font(.headline)
                    .foregroundColor(.gray)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: FeedPreferencesView()) {
                    Image(systemName: "gear")
                        .font(.title2)
                }
            }
        }
    }
}

#Preview {
    MainTabView()
}
