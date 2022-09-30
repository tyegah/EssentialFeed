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


//** These date extensions are separated because one is for Cache Policy DSL and the other is just a helper than can be reused in another component
extension Date {
    func minusFeedCacheMaxAge() -> Date {
        return adding(days: -feedCacheMaxAgeInDays)
    }
    
    private var feedCacheMaxAgeInDays: Int {
        return 7
    }
    
    private func adding(days: Int) -> Date {
        Calendar(identifier: .gregorian).date(byAdding: .day, value: days, to: self)!
    }
}

extension Date {
    func adding(seconds: TimeInterval) -> Date {
        self + seconds
    }
}
