//
//  Job.swift
//  RemoteRecruit
//
//  Created by Saurabh Jaiswal on 07/06/26.
//

import Foundation

// Maps directly to the JSON shape returned by the Remotive API
struct Job: Identifiable, Decodable {
    let id: Int
    let title: String
    let company_name: String
    let candidate_required_location: String
    let salary: String
    let description: String
    let url: String
    let job_type: String?
    let tags: [String]?
    
    var salaryDisplay: String {
        salary.isEmpty ? "Not specified" : salary
    }
    
    var locationDisplay: String {
        candidate_required_location.isEmpty ? "Remote" : candidate_required_location
    }
}

struct JobsResponse: Decodable {
    let jobs: [Job]
}
