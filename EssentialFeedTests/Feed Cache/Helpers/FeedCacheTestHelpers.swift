//
//  FeedCacheTestHelpers.swift
//  EssentialFeedTests
//
//  Created by Ty Septiani on 29/09/22.
//

import Foundation
import EssentialFeed

func uniqueImage() -> FeedImage {
    return FeedImage(id: UUID(), description: "any", location: "any", url: anyURL())
}

func uniqueImageFeed() -> (models:[FeedImage], locals: [LocalFeedImage]) {
    let imageFeed = [uniqueImage(), uniqueImage()]
    let localImageFeed = imageFeed.map { LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url)}
    return (imageFeed, localImageFeed)
}

extension Date {
    func adding(days: Int) -> Date {
        Calendar(identifier: .gregorian).date(byAdding: .day, value: days, to: self)!
    }
    
    func adding(seconds: TimeInterval) -> Date {
        self + seconds
    }
}
