//
//  TaskTableViewController.swift
//  RSDCatalog
//
//  Copyright © 2018 Sage Bionetworks. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//
// 1.  Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
//
// 2.  Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation and/or
// other materials provided with the distribution.
//
// 3.  Neither the name of the copyright holder(s) nor the names of any contributors
// may be used to endorse or promote products derived from this software without
// specific prior written permission. No license is granted to the trademarks of
// the copyright holders even if such marks are included in this software.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

import UIKit
import MotorControl
import Research
import ResearchUI
import BridgeApp

class TaskTableViewController: UITableViewController, RSDTaskViewControllerDelegate {

    @IBOutlet weak var participantIDLabel: UILabel!
    
    var participantID : String!
    let archiveManager = SBAArchiveManager()
    
    // A list of all the tasks included in this module.
    //var tasks =  MCTTaskIdentifier.all().map {MCTTaskInfo($0)}
    //@QUESTION FOR SHANNON: how to get a survey from Bridge Study Manager here and interact with AppConfig?
        //For now, if you don't have a more complicated scehdule, hard code this here instead
        //Note that for new tasks, can make them as a framework within a workspace, but even if you do this within this project, MAKE SURE TO MAKE A SEPARATE STORYBOARD
    var tasks = [MCTTaskInfo(MCTTaskIdentifier.walk30Seconds)]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.participantIDLabel.text = "Current Participant ID: " + self.participantID

        // Use automatic hieght dimension
        tableView.rowHeight = UITableView.automaticDimension
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Dynamic sizing for the header view
        if let headerView = tableView.tableHeaderView {
            let height = headerView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
            var headerFrame = headerView.frame
            
            // If we don't have this check, viewDidLayoutSubviews() will get
            // repeatedly, causing the app to hang.
            if height != headerFrame.size.height {
                headerFrame.size.height = height
                headerView.frame = headerFrame
                tableView.tableHeaderView = headerView
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        flushTempDirectory()
    }
    
    let offMainQueue = DispatchQueue(label: "org.sagebase.Research.Serialized.\(UUID())")
    
    /// Flush the temporary directory contents.
    /// For the example app, we want to leave the output directory untouched *until*
    /// this view controller appears. For a *real* application, the output directory
    /// that is used to store temporary results should be flushed as soon as the task
    /// is completed and the results are encrypted. This is because the results of the
    /// task could include private health data so it is important to handle these results
    /// using a secure method.
    func flushTempDirectory() {
        do {
            let fileManager = FileManager.default
            let tempDir = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            let directories = try fileManager.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil, options: [])
            for outputDirectory in directories {
                try FileManager.default.removeItem(at: outputDirectory)
            }
        } catch let error {
            print("Error removing output directory: \(error.localizedDescription)")
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tasks.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BasicCell", for: indexPath) as! ImageTableViewCell
        let taskInfo = tasks[indexPath.row]
        cell.titleLabel?.text = taskInfo.title ?? taskInfo.identifier
        cell.subtitleLabel?.text = taskInfo.subtitle
        if let imageView = cell.thumbnailView {
            taskInfo.imageVendor?.fetchImage(for: imageView.bounds.size) { (_, img) in
                imageView.image = img
            }
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let taskInfo = tasks[indexPath.row]
        let taskViewModel = RSDTaskViewModel(taskInfo: taskInfo)
        var answerResult = RSDAnswerResultObject(identifier: "participantID", answerType: .string)
        answerResult.value = self.participantID
        taskViewModel.taskResult.appendAsyncResult(with: answerResult)
        let taskViewController = RSDTaskViewController(taskViewModel: taskViewModel)
        taskViewController.delegate = self
        self.present(taskViewController, animated: true) {
            tableView.deselectRow(at: indexPath, animated: false)
        }
        
    }
    
    // MARK: - RSDTaskControllerDelegate
    
    func taskController(_ taskController: RSDTaskController, didFinishWith reason: RSDTaskFinishReason, error: Error?) {
        
        // dismiss the view controller
        (taskController as? UIViewController)?.dismiss(animated: true) {
        }
    }
    
    func taskController(_ taskController: RSDTaskController, readyToSave taskViewModel: RSDTaskViewModel) {
        print("\n\n=== Ready to Save: \(taskViewModel.description)")
        
        taskViewModel.archiveResults(with: self.archiveManager) { (_) in
            
        }
    }
    
}

class ImageTableViewCell : UITableViewCell {
    
    @IBOutlet weak var thumbnailView: UIImageView?
    @IBOutlet weak var titleLabel: UILabel?
    @IBOutlet weak var subtitleLabel: UILabel?
    
}


