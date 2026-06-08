//
//  RemoteRecruitUITests.swift
//  RemoteRecruitUITests
//
//  Created by Saurabh Jaiswal on 08/06/26.
//

import XCTest

final class RemoteRecruitUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {

        continueAfterFailure = false

        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Helpers

    private func openFirstJob() {

        let table = app.tables["jobList"]

        XCTAssertTrue(
            table.waitForExistence(timeout: 15),
            "Job list should exist"
        )

        let firstCell = table.cells.firstMatch

        XCTAssertTrue(
            firstCell.waitForExistence(timeout: 15),
            "First job should exist"
        )

        firstCell.tap()
    }
    
    func test_navigationTitleExists() {

        XCTAssertTrue(
            app.navigationBars["Remote Jobs"]
                .waitForExistence(timeout: 5)
        )
    }
    
    
    func test_searchBarExists() {

        XCTAssertTrue(
            app.searchFields[
                "Search by title or company"
            ]
            .waitForExistence(timeout: 5)
        )
    }
    
    
    func test_jobListLoads() {

        let table = app.tables["jobList"]

        XCTAssertTrue(
            table.waitForExistence(timeout: 15)
        )
    }
    
    
    func test_searchFieldAcceptsInput() {

        let searchField = app.searchFields[
            "Search by title or company"
        ]

        XCTAssertTrue(
            searchField.waitForExistence(timeout: 5)
        )

        searchField.tap()
        searchField.typeText("iOS")

        XCTAssertTrue(
            searchField.exists
        )
    }
    
    func test_openJobDetail() {

        openFirstJob()

        XCTAssertTrue(
            app.staticTexts["jobDescriptionTitle"]
                .waitForExistence(timeout: 10)
        )
    }
    
    func test_scrollJobDetail() {

        openFirstJob()

        let scrollView =
            app.scrollViews.firstMatch

        XCTAssertTrue(
            scrollView.waitForExistence(timeout: 5)
        )

        scrollView.swipeUp()
        scrollView.swipeDown()
    }
    
    
    func test_backNavigationWorks() {

        openFirstJob()

        app.navigationBars
            .buttons
            .firstMatch
            .tap()

        XCTAssertTrue(
            app.navigationBars["Remote Jobs"]
                .waitForExistence(timeout: 5)
        )
    }
    
    
    
}
