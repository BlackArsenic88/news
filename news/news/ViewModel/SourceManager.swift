//
//  SourceManager.swift
//  Quartic
//
//  Created by Abraham Doe on 5/22/25.
//

import Foundation
import Combine

class SourceManager: ObservableObject {
    static let shared = SourceManager()

    @Published var selectedSources: Set<String> = []

    let feeds: [(String, String)] = [
        ("Cornell Business", "https://business.cornell.edu/feed/"),
        ("Harvard Business Review", "hbr://feed"),
        ("MIT Sloan", "https://sloanreview.mit.edu/feed/"),
        ("Wharton", "https://knowledge.wharton.upenn.edu/feed/"),
        ("CNBC Business", "https://www.cnbc.com/id/10001147/device/rss/rss.html"),
        ("CNBC Economy", "https://www.cnbc.com/id/20910258/device/rss/rss.html"),
        ("CNBC Finance", "https://www.cnbc.com/id/10000664/device/rss/rss.html"),
        ("CNBC Investing", "https://www.cnbc.com/id/15839069/device/rss/rss.html"),
        ("CNBC Market Insider", "https://www.cnbc.com/id/20409666/device/rss/rss.html"),
        ("CNBC Personal Finance", "https://www.cnbc.com/id/21324812/device/rss/rss.html"),
        ("CNBC Technology", "https://www.cnbc.com/id/19854910/device/rss/rss.html"),
        ("CNBC U.S. News", "https://www.cnbc.com/id/15837362/device/rss/rss.html"),
        ("CNBC World News", "https://www.cnbc.com/id/100727362/device/rss/rss.html")
    ]
    
    /*
     Additional Informaton Sources
         // Business Administration
         ("BBC News", "https://www.bbc.com/news"),
         ("Columbia Business", "https://www8.gsb.columbia.edu/ideas-at-work/rss"),
         ("Cornell Business", "https://business.cornell.edu/feed/"),
         ("Dartmouth Knowledge in Practice", "https://tuck.dartmouth.edu/news/category/faculty-insights"),
         ("Dartmouth Media", "https://tuck.dartmouth.edu/news/category/in-the-media"),
         ("Hacker News", "https://news.ycombinator.com/"),
         ("Harvard Business Review", "https://hbr.org"),
         ("Knowledge @ Wharton", "https://knowledge.wharton.upenn.edu/feed/"),
         ("MIT Sloan", "https://sloanreview.mit.edu/feed/"),
         ("Morningstar", "https://www.morningstar.com/videos"),
         ("The New Yorker", " https://www.newyorker.com"),
         ("Yale", "https://insights.som.yale.edu"),
         
         // Finance & Investing
         ("CFA Institute: Research & Policy Center", "https://rpc.cfainstitute.org/research/browse#sortCriteria=%40officialz32xdate%20descending"),
         ("CFA Institute: Enterprising Investor", "https://blogs.cfainstitute.org/investor/" ),
         ("CNBC Economy", "https://www.cnbc.com/id/20910258/device/rss/rss.html"),
         ("CNBC Finance", "https://www.cnbc.com/id/10000664/device/rss/rss.html"),
         ("US News & World", "https://www.usnews.com/topics/business-and-finance/rss"),
         
         // Human Resources
         // ("American Medical Association", "https://www.ama-assn.org"),
         // ("American Neurological Association", "https://myana.org/news/page/2/"),
         // ("American Heart Association https", "https://www.heart.org/en/news"),
         // ("Harvard Medical Publishing", "https://www.health.harvard.edu"),
         // ("Mayo Clinic", "https://newsnetwork.mayoclinic.org"),
         // ("US News & World Report", "https://www.usnews.com"),
         
         // Law
         // ("Legal Intelligencer", "https://www.law.com/thelegalintelligencer/" ),
         // ("Legal Tech", "https://www.law.com/legaltechnews/", false ),
         // ("New York Law Journal", "https://www.law.com/newyorklawjournal/"),
         // ("Supreme Court Brief", "https://www.law.com/supremecourtbrief/" ),
         // ("Texas Lawyer", "https://www.law.com/texaslawyer/"),
         // ("SCOTUS", "https://www.supremecourt.gov/publicinfo/press/pressreleases.aspx"),
         // ("White House", "https://www.whitehouse.gov/news/"),

         // Marketing
         // ("UN Sustainable Development Goals", "https://sdgs.un.org/news?page=%2C%2C0"),
         // ("International", "https://www.newspaperindex.com"),
         
         // Operations
         // ("San Pellegrino 50 Best", "https://mediacentre.theworlds50best.com/#/hierarchies"),
         // ("Olympics", "https://www.olympics.com/ioc/news"),
         // ("Nobel", "https://www.nobelprize.org/feed/"),
         
         // Technology
         // ("CNBC Technology", "https://www.cnbc.com/id/19854910/device/rss/rss.html")
         // ("CIO Dive", "https://www.ciodive.com"),
         // ("CNET", "https://www.cnet.com"),
         // ("Dark Reading", "https://www.darkreading.com"),
         // ("Hacker News", "https://thehackernews.com"),
         // ("Tech Crunch", "https://techcrunch.com"),
         // ("TLDR", "https://tldr.tech"),
         // ("Wired", "https://www.wired.com")
     */

    private init() {
        loadPreferences()
    }

    func feedURLs() -> [String] {
        feeds.filter { selectedSources.contains($0.0) }.map { $0.1 }
    }

    func savePreferences() {
        UserDefaults.standard.set(Array(selectedSources), forKey: "SelectedSources")
    }

    func loadPreferences() {
        if let saved = UserDefaults.standard.array(forKey: "SelectedSources") as? [String] {
            selectedSources = Set(saved)
        } else {
            selectedSources = Set(feeds.prefix(5).map { $0.0 })
        }
    }
}

class RSSViewModel: ObservableObject {
    @Published var items: [RSSItem] = []
    private var cancellables = Set<AnyCancellable>()
    private var allItems: [RSSItem] = []
    private var batchSize = 10
    private var currentOffset = 0

    func loadFeeds(from urls: [String], completion: @escaping () -> Void = {}) {
        items = []
        allItems = []
        currentOffset = 0

        let group = DispatchGroup()
        var aggregatedItems: [RSSItem] = []

        let allFeeds = SourceManager.shared.feeds
        let selectedFeeds = allFeeds.filter { urls.contains($0.1) }

        for (name, urlString) in selectedFeeds {
            if let feedURL = URL(string: urlString) {
                group.enter()
                RSSParser().parseFeed(url: feedURL, source: name) { parsed in
                    aggregatedItems.append(contentsOf: parsed)
                    group.leave()
                }
            }
        }

        group.notify(queue: .main) {
            self.allItems = Array(Set(aggregatedItems)).sorted(by: { $0.pubDate > $1.pubDate })
            self.loadMoreItems()
            completion() // ✅ Trigger after loading
        }
    }

    func loadMoreItems() {
        guard currentOffset < allItems.count else { return }
        let nextBatch = allItems[currentOffset..<min(currentOffset + batchSize, allItems.count)]
        items.append(contentsOf: nextBatch)
        currentOffset += batchSize
    }
    
    func preloadItems(_ newItems: [RSSItem]) {
        self.items = newItems
        self.allItems = newItems
        self.currentOffset = newItems.count
    }
}
