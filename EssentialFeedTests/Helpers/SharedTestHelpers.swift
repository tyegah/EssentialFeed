//
//  SharedTestHelpers.swift
//  EssentialFeedTests
//
//  Created by Ty Septiani on 29/09/22.
//

import Foundation

func anyNSError() -> NSError {
    return NSError(domain: "any error", code: 1)
}

func anyURL() -> URL {
    return URL(string: "https://any-url.com")!
}
