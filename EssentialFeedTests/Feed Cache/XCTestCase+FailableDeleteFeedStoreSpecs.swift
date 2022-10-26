//
//  XCTestCase+FailableDeleteFeedStoreSpecs.swift
//  EssentialFeedTests
//
//  Created by Ty Septiani on 26/10/22.
//

import Foundation

import XCTest
import EssentialFeed

extension FailableDeleteFeedStoreSpecs where Self: XCTestCase {
    func assertThatDeleteDeliversErrorOnDeletionError(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        let deletionError = deleteCacheFeed(from: sut)
        XCTAssertNotNil(deletionError, "Expected deletion to fail with an error", file: file, line: line)
    }
    
    func assertThatDeleteHasNoSideEffectOnDeletionError(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        deleteCacheFeed(from: sut)
        expect(sut, toRetrieve: .empty)
    }
}
