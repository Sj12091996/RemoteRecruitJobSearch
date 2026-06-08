//
//  JobDetailViewModel.swift
//  RemoteRecruit
//
//  Created by Saurabh Jaiswal on 07/06/26.
//

import Foundation

@MainActor
class JobDetailViewModel: ObservableObject {
    
    let job: Job
    
    init(job: Job) {
        self.job = job
    }
    
    var title: String { job.title }
    var company: String { job.company_name }
    var location: String { job.locationDisplay }
    var salary: String { job.salaryDisplay }
    var description: String { job.description }
    var jobType: String { job.job_type ?? "Full-time" }
    var tags: [String] { job.tags ?? [] }
    var jobURL: URL? { URL(string: job.url) }
}
