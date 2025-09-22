//
//  NewsView.swift
//  Quartic
//
//  Created by Abraham Doe on 5/22/25.
//

import SwiftUI
import SafariServices

// Wrapper to make URL Identifiable for SwiftUI sheet
struct IdentifiableURL: Identifiable {
    let id = UUID()
    let url: URL
}

// Main news view displaying feed items with infinite scroll
struct NewsView: View {
    @StateObject private var viewModel = RSSViewModel()
    @State private var selectedURL: IdentifiableURL?
    @ObservedObject var sourceManager = SourceManager.shared

    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.items) { item in
                    VStack(alignment: .leading, spacing: 10) {
                        if let imageURL = item.imageURL, let url = URL(string: imageURL) {
                            AsyncImage(url: url) { image in
                                image.resizable().aspectRatio(contentMode: .fill).frame(height: 200).clipped()
                            } placeholder: {
                                Color.gray.frame(height: 200)
                            }
                        }
                        Text(item.title).font(.headline)
                        Text(item.description).font(.body).lineLimit(3)
                        Text(item.source)
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(formattedDate(from: item.pubDate))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .onTapGesture {
                        if let url = URL(string: item.link) {
                            selectedURL = IdentifiableURL(url: url)
                        }
                    }
                    .onAppear {
                        if item == viewModel.items.last {
                            viewModel.loadMoreItems()
                        }
                    }
                }
            }
             .onAppear {
                viewModel.loadFeeds(from: sourceManager.feedURLs())
            }
            .sheet(item: $selectedURL) { wrapper in
                SafariView(url: wrapper.url)
            }
            .navigationTitle("News")
        }
    }
    
    func formattedDate(from rawDate: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E, d MMM yyyy HH:mm:ss Z" // Typical RSS format
        if let date = formatter.date(from: rawDate) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .full // "Thursday, May 23, 2025"
            return displayFormatter.string(from: date)
        }
        return rawDate // fallback
    }
}

// In-app browser using SafariServices
struct SafariView: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

struct NewsView_Previews: PreviewProvider {
    static var previews: some View {
        NewsView()
    }
}
