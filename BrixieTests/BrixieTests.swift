//
//  BrixieTests.swift
//  BrixieTests
//
//  Created by Matthias Wallner-Géhri on 01.09.25.
//

import Testing
import SwiftUI
@testable import Brixie

struct BrixieTests {

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }

    @Test func skeletonComponentsCanBeCreated() async throws {
        // Test that skeleton components can be instantiated without crashing
        let skeletonView = SkeletonView()
        let skeletonTextLine = SkeletonTextLine(width: 100, height: 16)
        let skeletonImage = SkeletonImage(width: 60, height: 60)
        let setRowSkeleton = SetRowSkeleton()
        let skeletonListView = SkeletonListView(itemCount: 5)

        // If we reach here without crashing, the components are properly configured
        #expect(true)
    }

}
