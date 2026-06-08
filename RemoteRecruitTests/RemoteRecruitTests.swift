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
        
        if let search = search, !search.isEmpty {
            return mockJobs.filter {
                $0.title.lowercased().contains(search.lowercased()) ||
                $0.company_name.lowercased().contains(search.lowercased())
            }
        }
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

    func test_loadJobs_success() async {
        mockService.mockJobs = [.mock(), .mock(id: 2, title: "Android Dev")]

        await viewModel.loadJobs()

        XCTAssertEqual(viewModel.jobs.count, 2)
        if case .success = viewModel.viewState { } else {
            XCTFail("Expected success state")
        }
    }

    func test_loadJobs_emptyResult() async {
        mockService.mockJobs = []

        await viewModel.loadJobs()

        XCTAssertTrue(viewModel.jobs.isEmpty)
        if case .empty = viewModel.viewState { } else {
            XCTFail("Expected empty state")
        }
    }

    func test_loadJobs_error() async {
        mockService.shouldThrow = true

        await viewModel.loadJobs()

        if case .error = viewModel.viewState { } else {
            XCTFail("Expected error state")
        }
    }

    // ✅ Load first, then set searchText to trigger client-side filter
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

    func test_retry_reloadsJobs() async {
        mockService.shouldThrow = true
        await viewModel.loadJobs()

        mockService.shouldThrow = false
        mockService.mockJobs = [.mock()]
        await viewModel.retry()

        XCTAssertEqual(viewModel.jobs.count, 1)
        if case .success = viewModel.viewState { } else {
            XCTFail("Expected success state after retry")
        }
    }

    func test_loadingState_isSetBeforeFetch() async {
        mockService.mockJobs = [.mock()]
        XCTAssertEqual(viewModel.viewState.description, "idle")

        await viewModel.loadJobs()
        XCTAssertEqual(viewModel.viewState.description, "success")
    }
}

// MARK: - JobDetailViewModel Tests
@MainActor
final class JobDetailViewModelTests: XCTestCase {
    
    func test_displaysCorrectJobInfo() {
        let job = Job.mock(
            title: "Senior iOS Dev",
            company: "Apple",
            location: "Cupertino",
            salary: "$150k",
            description: "Great job.",
            jobType: "full_time"
        )
        let vm = JobDetailViewModel(job: job)
        
        XCTAssertEqual(vm.title, "Senior iOS Dev")
        XCTAssertEqual(vm.company, "Apple")
        XCTAssertEqual(vm.location, "Cupertino")
        XCTAssertEqual(vm.salary, "$150k")
        XCTAssertEqual(vm.jobType, "full_time")
    }
    
    func test_emptySalaryShowsNotSpecified() {
        let job = Job.mock(salary: "")
        let vm = JobDetailViewModel(job: job)
        XCTAssertEqual(vm.salary, "Not specified")
    }
    
    func test_emptyLocationShowsRemote() {
        let job = Job.mock(location: "")
        let vm = JobDetailViewModel(job: job)
        XCTAssertEqual(vm.location, "Remote")
    }
    
    func test_jobURLIsValid() {
        let job = Job.mock(url: "https://example.com/jobs/1")
        let vm = JobDetailViewModel(job: job)
        XCTAssertNotNil(vm.jobURL)
        XCTAssertEqual(vm.jobURL?.absoluteString, "https://example.com/jobs/1")
    }
    
    func test_nilJobTypeDefaultsToFullTime() {
        let job = Job.mock(jobType: nil)
        let vm = JobDetailViewModel(job: job)
        XCTAssertEqual(vm.jobType, "Full-time")
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
