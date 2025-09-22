//
//  FeedPreferencesView.swift
//  Quartic
//
//  Created by Abraham Doe on 5/22/25.
//

import SwiftUI

// View allowing users to select which RSS sources appear in their feed
struct FeedPreferencesView: View {
    @ObservedObject var manager = SourceManager.shared

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Sources")) {
                    ForEach(manager.feeds, id: \.0) { (name, _) in
                        Toggle(name, isOn: Binding(
                            get: { manager.selectedSources.contains(name) },
                            set: { isOn in
                                if isOn {
                                    manager.selectedSources.insert(name)
                                } else {
                                    manager.selectedSources.remove(name)
                                }
                                manager.savePreferences()
                            }
                        )).tint(.blue)
                    }
                }
            }
            .navigationTitle("Customize News Feed")
        }
    }
}
