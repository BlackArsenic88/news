//
//  RSSModel.swift
//  Quartic
//
//  Created by Abraham Doe on 5/22/25.
//
import Foundation

struct RSSItem: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let link: String
    let pubDate: String
    let description: String
    let imageURL: String?
    let source: String
}

import Foundation

class RSSParser: NSObject, XMLParserDelegate {
    private var items: [RSSItem] = []
    private var currentElement = ""
    private var currentTitle = ""
    private var currentLink = ""
    private var currentPubDate = ""
    private var currentDescription = ""
    private var currentImageURL: String? = nil
    private var completionHandler: (([RSSItem]) -> Void)?
    private var currentSource: String = ""

    func parseFeed(url: URL, source: String, completion: @escaping ([RSSItem]) -> Void) {
        if url.scheme == "hbr" {
            // Return static articles immediately
            completion(HBRArticles.items)
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data else {
                completion([])
                return
            }
            let parser = XMLParser(data: data)
            self.currentSource = source
            self.completionHandler = completion
            parser.delegate = self
            parser.parse()
        }.resume()
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        if elementName == "item" {
            currentTitle = ""
            currentLink = ""
            currentPubDate = ""
            currentDescription = ""
            currentImageURL = nil
        }
        if (elementName == "media:content" || elementName == "enclosure"), let url = attributeDict["url"] {
            currentImageURL = url
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        switch currentElement {
        case "title": currentTitle += string
        case "link": currentLink += string
        case "pubDate": currentPubDate += string
        case "description": currentDescription += string
        default: break
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "item" {
            // Fallback: extract first <img> src from description if no media:content or enclosure found
            if currentImageURL == nil,
               let imgURL = currentDescription.firstMatch(of: #"<img.*?src=["'](.*?)["']"#, group: 1) {
                currentImageURL = imgURL
            }

            let item = RSSItem(
                title: currentTitle.decodedHTML,
                link: currentLink.trimmingCharacters(in: .whitespacesAndNewlines),
                pubDate: currentPubDate.trimmingCharacters(in: .whitespacesAndNewlines),
                description: (currentSource == "Hacker News"
                              ? ""
                              : currentDescription.decodedHTML),
                imageURL: currentImageURL,
                source: currentSource
            )
            items.append(item)
        }
    }


    func parserDidEndDocument(_ parser: XMLParser) {
        completionHandler?(items)
    }
}

private extension String {
    var decodedHTML: String {
        let data = Data(self.utf8)
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        return (try? NSAttributedString(data: data, options: options, documentAttributes: nil).string) ?? self
    }
    
    func firstMatch(of pattern: String, group: Int = 1) -> String? {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: self, options: [], range: NSRange(self.startIndex..., in: self)),
               let range = Range(match.range(at: group), in: self) {
                return String(self[range])
            }
            return nil
        }
}
