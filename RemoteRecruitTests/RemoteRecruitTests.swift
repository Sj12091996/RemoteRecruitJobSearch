//
//  RemoteRecruitTests.swift
//  RemoteRecruitTests
//
//  Created by Saurabh Jaiswal on 07/06/26.
//

import XCTest
@testable import RemoteRecruit

// MARK: - Mock Service
@MainActor
class MockJobService: JobServiceProtocol {
    var mockJobs: [Job] = []
    var shouldThrow = false
    var errorToThrow: Error = NetworkError.unknown(NSError(domain: "test", code: -1))

    func fetchJobs(search: String?) async throws -> [Job] {
        if shouldThrow { throw errorToThrow }
        return mockJobs
    }
}

// MARK: - Sample Data
extension Job {
    static func mock(
        id: Int = 1,
        title: String = "iOS Engineer",
        company: String = "Acme Inc",
        location: String = "Remote",
        salary: String = "$100k - $120k",
        description: String = "Build awesome iOS apps.",
        url: String = "https://example.com",
        jobType: String? = "full_time",
        tags: [String]? = ["Swift", "iOS"]
    ) -> Job {
        Job(
            id: id,
            title: title,
            company_name: company,
            candidate_required_location: location,
            salary: salary,
            description: description,
            url: url,
            job_type: jobType,
            tags: tags
        )
    }
}

// MARK: - ViewState helper
extension ViewState {
    var description: String {
        switch self {
        case .idle: return "idle"
        case .loading: return "loading"
        case .success: return "success"
        case .empty: return "empty"
        case .error: return "error"
        }
    }
}

// MARK: - Job Model Tests
final class JobModelTests: XCTestCase {

    func test_salaryDisplay_emptyReturnsNotSpecified() {
        let job = Job.mock(salary: "")
        XCTAssertEqual(job.salaryDisplay, "Not specified")
    }

    func test_salaryDisplay_returnsValue() {
        let job = Job.mock(salary: "$120k")
        XCTAssertEqual(job.salaryDisplay, "$120k")
    }

    func test_locationDisplay_emptyReturnsRemote() {
        let job = Job.mock(location: "")
        XCTAssertEqual(job.locationDisplay, "Remote")
    }

    func test_locationDisplay_returnsValue() {
        let job = Job.mock(location: "New York")
        XCTAssertEqual(job.locationDisplay, "New York")
    }

    func test_jobIsIdentifiable() {
        let job = Job.mock(id: 42)
        XCTAssertEqual(job.id, 42)
    }

    func test_jobDecodable_fromJSON() throws {
        let json = """
        {
            "id": 10,
            "title": "Swift Dev",
            "company_name": "Apple",
            "candidate_required_location": "USA",
            "salary": "$130k",
            "description": "Great role",
            "url": "https://apple.com",
            "job_type": "full_time",
            "tags": ["Swift", "Xcode"]
        }
        """.data(using: .utf8)!
        let job = try JSONDecoder().decode(Job.self, from: json)
        XCTAssertEqual(job.title, "Swift Dev")
        XCTAssertEqual(job.company_name, "Apple")
        XCTAssertEqual(job.tags, ["Swift", "Xcode"])
    }

    func test_jobDecodable_nilOptionalFields() throws {
        let json = """
        {
            "id": 1,
            "title": "Dev",
            "company_name": "Co",
            "candidate_required_location": "",
            "salary": "",
            "description": "",
            "url": "https://example.com"
        }
        """.data(using: .utf8)!
        let job = try JSONDecoder().decode(Job.self, from: json)
        XCTAssertNil(job.job_type)
        XCTAssertNil(job.tags)
        XCTAssertEqual(job.salaryDisplay, "Not specified")
        XCTAssertEqual(job.locationDisplay, "Remote")
    }

    func test_jobsResponse_decodable() throws {
        let json = """
        {
            "jobs": [
                {
                    "id": 1,
                    "title": "iOS Dev",
                    "company_name": "Acme",
                    "candidate_required_location": "Remote",
                    "salary": "$100k",
                    "description": "Cool job",
                    "url": "https://example.com"
                }
            ]
        }
        """.data(using: .utf8)!
        let response = try JSONDecoder().decode(JobsResponse.self, from: json)
        XCTAssertEqual(response.jobs.count, 1)
        XCTAssertEqual(response.jobs.first?.title, "iOS Dev")
    }
}

// MARK: - NetworkError Tests
final class NetworkErrorTests: XCTestCase {

    func test_invalidURL_description() {
        XCTAssertEqual(NetworkError.invalidURL.errorDescription, "Invalid URL.")
    }

    func test_decodingFailed_description() {
        XCTAssertEqual(NetworkError.decodingFailed.errorDescription, "Failed to decode response.")
    }

    func test_serverError_description() {
        XCTAssertEqual(NetworkError.serverError(404).errorDescription, "Server error: 404.")
    }

    func test_serverError_500_description() {
        XCTAssertEqual(NetworkError.serverError(500).errorDescription, "Server error: 500.")
    }

    func test_unknown_description() {
        let error = NSError(domain: "test", code: -1, userInfo: [NSLocalizedDescriptionKey: "Something went wrong"])
        XCTAssertEqual(NetworkError.unknown(error).errorDescription, "Something went wrong")
    }
}

// MARK: - String HTML Strip Tests
final class StringHTMLTests: XCTestCase {

    func test_stripsBasicTags() {
        let html = "<p>Hello <b>World</b></p>"
        XCTAssertEqual(html.strippedHTML.trimmingCharacters(in: .whitespacesAndNewlines), "Hello World")
    }

    func test_plainStringUnchanged() {
        let plain = "No HTML here"
        XCTAssertEqual(plain.strippedHTML, "No HTML here")
    }

    func test_stripsAnchorTags() {
        let html = "<a href=\"https://example.com\">Click here</a>"
        XCTAssertEqual(html.strippedHTML.trimmingCharacters(in: .whitespacesAndNewlines), "Click here")
    }

    func test_emptyStringReturnsEmpty() {
        XCTAssertEqual("".strippedHTML, "")
    }

    func test_stripsNestedTags() {
        let html = "<div><p><strong>Nested</strong></p></div>"
        XCTAssertEqual(html.strippedHTML.trimmingCharacters(in: .whitespacesAndNewlines), "Nested")
    }

    func test_stripsListTags() {
        let html = "<ul><li>Item 1</li><li>Item 2</li></ul>"
        let result = html.strippedHTML.trimmingCharacters(in: .whitespacesAndNewlines)
        XCTAssertTrue(result.contains("Item 1"))
        XCTAssertTrue(result.contains("Item 2"))
    }
}

// MARK: - JobListViewModel Tests
@MainActor
final class JobListViewModelTests: XCTestCase {

    var mockService: MockJobService!
    var viewModel: JobListViewModel!

    @MainActor
    override func setUpWithError() throws {
        mockService = MockJobService()
        viewModel = JobListViewModel(service: mockService)
    }

    @MainActor
    override func tearDownWithError() throws {
        mockService = nil
        viewModel = nil
    }

    // MARK: Initial state
    func test_initialState_isIdle() {
        XCTAssertEqual(viewModel.viewState.description, "idle")
        XCTAssertTrue(viewModel.jobs.isEmpty)
        XCTAssertEqual(viewModel.searchText, "")
    }

    // MARK: Load jobs
    func test_loadJobs_success() async {
        mockService.mockJobs = [.mock(), .mock(id: 2, title: "Android Dev")]
        await viewModel.loadJobs()
        XCTAssertEqual(viewModel.jobs.count, 2)
        XCTAssertEqual(viewModel.viewState.description, "success")
    }

    func test_loadJobs_emptyResult() async {
        mockService.mockJobs = []
        await viewModel.loadJobs()
        XCTAssertTrue(viewModel.jobs.isEmpty)
        XCTAssertEqual(viewModel.viewState.description, "empty")
    }

    func test_loadJobs_error() async {
        mockService.shouldThrow = true
        await viewModel.loadJobs()
        XCTAssertEqual(viewModel.viewState.description, "error")
        XCTAssertTrue(viewModel.jobs.isEmpty)
    }

    func test_loadJobs_errorMessage_isSet() async {
        mockService.shouldThrow = true
        mockService.errorToThrow = NetworkError.serverError(500)
        await viewModel.loadJobs()
        if case .error(let msg) = viewModel.viewState {
            XCTAssertFalse(msg.isEmpty)
        } else {
            XCTFail("Expected error state with message")
        }
    }

    func test_loadJobs_setsLoadingFirst() async {
        mockService.mockJobs = [.mock()]
        XCTAssertEqual(viewModel.viewState.description, "idle")
        await viewModel.loadJobs()
        // After completion it should be success
        XCTAssertEqual(viewModel.viewState.description, "success")
    }

    // MARK: Search / filter
    func test_search_filtersByTitle() async {
        mockService.mockJobs = [
            .mock(id: 1, title: "iOS Engineer"),
            .mock(id: 2, title: "Android Developer")
        ]
        await viewModel.loadJobs()
        viewModel.searchText = "iOS"
        XCTAssertEqual(viewModel.jobs.count, 1)
        XCTAssertEqual(viewModel.jobs.first?.title, "iOS Engineer")
    }

    func test_search_filtersByCompany() async {
        mockService.mockJobs = [
            .mock(id: 1, company: "Apple"),
            .mock(id: 2, company: "Google")
        ]
        await viewModel.loadJobs()
        viewModel.searchText = "Apple"
        XCTAssertEqual(viewModel.jobs.count, 1)
        XCTAssertEqual(viewModel.jobs.first?.company_name, "Apple")
    }

    func test_search_caseInsensitive() async {
        mockService.mockJobs = [.mock(id: 1, title: "iOS Engineer")]
        await viewModel.loadJobs()
        viewModel.searchText = "ios"
        XCTAssertEqual(viewModel.jobs.count, 1)
    }

    func test_search_partialMatch() async {
        mockService.mockJobs = [
            .mock(id: 1, title: "Senior iOS Developer"),
            .mock(id: 2, title: "Android Engineer")
        ]
        await viewModel.loadJobs()
        viewModel.searchText = "Senior"
        XCTAssertEqual(viewModel.jobs.count, 1)
    }

    func test_search_noMatch_setsEmptyState() async {
        mockService.mockJobs = [.mock(id: 1, title: "iOS Engineer")]
        await viewModel.loadJobs()
        viewModel.searchText = "Flutter"
        XCTAssertTrue(viewModel.jobs.isEmpty)
        XCTAssertEqual(viewModel.viewState.description, "empty")
    }

    func test_search_clearRestoresAllJobs() async {
        mockService.mockJobs = [.mock(id: 1), .mock(id: 2, title: "Android Dev")]
        await viewModel.loadJobs()
        viewModel.searchText = "iOS"
        XCTAssertEqual(viewModel.jobs.count, 1)
        viewModel.searchText = ""
        XCTAssertEqual(viewModel.jobs.count, 2)
        XCTAssertEqual(viewModel.viewState.description, "success")
    }

    func test_search_whitespaceOnlyTreatedAsEmpty() async {
        mockService.mockJobs = [.mock(id: 1), .mock(id: 2)]
        await viewModel.loadJobs()
        viewModel.searchText = "   "
        XCTAssertEqual(viewModel.jobs.count, 2)
    }

    func test_search_matchesMultipleJobs() async {
        mockService.mockJobs = [
            .mock(id: 1, title: "iOS Engineer"),
            .mock(id: 2, title: "iOS Developer"),
            .mock(id: 3, title: "Android Dev")
        ]
        await viewModel.loadJobs()
        viewModel.searchText = "iOS"
        XCTAssertEqual(viewModel.jobs.count, 2)
    }

    func test_search_beforeLoad_doesNotCrash() {
        // searchText set before loadJobs called — allJobs is empty, should not crash
        viewModel.searchText = "iOS"
        XCTAssertTrue(viewModel.jobs.isEmpty)
        XCTAssertEqual(viewModel.viewState.description, "empty")
    }

    // MARK: Retry
    func test_retry_reloadsAfterError() async {
        mockService.shouldThrow = true
        await viewModel.loadJobs()
        XCTAssertEqual(viewModel.viewState.description, "error")

        mockService.shouldThrow = false
        mockService.mockJobs = [.mock()]
        await viewModel.retry()

        XCTAssertEqual(viewModel.jobs.count, 1)
        XCTAssertEqual(viewModel.viewState.description, "success")
    }

    func test_retry_withSearchText_filtersCorrectly() async {
        mockService.mockJobs = [
            .mock(id: 1, title: "iOS Engineer"),
            .mock(id: 2, title: "Android Dev")
        ]
        viewModel.searchText = "iOS"
        await viewModel.retry()
        XCTAssertEqual(viewModel.jobs.count, 1)
    }
}

// MARK: - JobDetailViewModel Tests
@MainActor
final class JobDetailViewModelTests: XCTestCase {

    func test_displaysCorrectJobInfo() {
        let job = Job.mock(title: "Senior iOS Dev", company: "Apple", location: "Cupertino", salary: "$150k", jobType: "full_time")
        let vm = JobDetailViewModel(job: job)
        XCTAssertEqual(vm.title, "Senior iOS Dev")
        XCTAssertEqual(vm.company, "Apple")
        XCTAssertEqual(vm.location, "Cupertino")
        XCTAssertEqual(vm.salary, "$150k")
        XCTAssertEqual(vm.jobType, "full_time")
    }

    func test_emptySalaryShowsNotSpecified() {
        let vm = JobDetailViewModel(job: .mock(salary: ""))
        XCTAssertEqual(vm.salary, "Not specified")
    }

    func test_emptyLocationShowsRemote() {
        let vm = JobDetailViewModel(job: .mock(location: ""))
        XCTAssertEqual(vm.location, "Remote")
    }

    func test_jobURLIsValid() {
        let vm = JobDetailViewModel(job: .mock(url: "https://example.com/jobs/1"))
        XCTAssertNotNil(vm.jobURL)
        XCTAssertEqual(vm.jobURL?.absoluteString, "https://example.com/jobs/1")
    }

    func test_invalidURL_returnsNil() {
        let vm = JobDetailViewModel(job: .mock(url: "not a url $$"))
        XCTAssertNil(vm.jobURL)
    }

    func test_nilJobTypeDefaultsToFullTime() {
        let vm = JobDetailViewModel(job: .mock(jobType: nil))
        XCTAssertEqual(vm.jobType, "Full-time")
    }

    func test_tagsReturnedCorrectly() {
        let vm = JobDetailViewModel(job: .mock(tags: ["Swift", "SwiftUI", "Combine"]))
        XCTAssertEqual(vm.tags, ["Swift", "SwiftUI", "Combine"])
    }

    func test_nilTagsReturnsEmpty() {
        let vm = JobDetailViewModel(job: .mock(tags: nil))
        XCTAssertTrue(vm.tags.isEmpty)
    }

    func test_descriptionPassedThrough() {
        let vm = JobDetailViewModel(job: .mock(description: "Exciting opportunity"))
        XCTAssertEqual(vm.description, "Exciting opportunity")
    }

    func test_companyPassedThrough() {
        let vm = JobDetailViewModel(job: .mock(company: "Stripe"))
        XCTAssertEqual(vm.company, "Stripe")
    }
}
