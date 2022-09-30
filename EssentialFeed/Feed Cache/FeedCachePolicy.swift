//
//  FeedCachePolicy.swift
//  EssentialFeed
//
//  Created by Ty Septiani on 30/09/22.
//

import Foundation

final class FeedCachePolicy {
    private static let calendar = Calendar(identifier: .gregorian)
    
    private init() {}
    
    //** LocalFeedLoader as UseCase should encapsulate application-specific logic only and communicate with models to perform business logic
    //** These two methods (maxCacheAgeInDays & validate timeStamp) are considered Rules & Policies or validation logic
    //** They're better suited in the Domain Model that is application agnostic (so it can be reused accross applications)
    //** This is why we create this FeedCachePolicy class
    
    private static var maxCacheAgeInDays:Int {
        return 7
    }
    
    static func validate(_ timestamp: Date, against date: Date) -> Bool {
        guard let maxCacheAge = calendar.date(byAdding: .day, value: maxCacheAgeInDays, to: timestamp) else {
            return false
        }
        return date < maxCacheAge
    }
}
