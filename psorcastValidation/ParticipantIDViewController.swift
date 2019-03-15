//
//  ParticipantIDViewController.swift
//  psorcastValidation
//
//  Created by Dan Webster on 3/15/19.
//  Copyright © 2019 Dan Webster. All rights reserved.
//

import UIKit

class ParticipantIDViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBOutlet weak var textField: UITextField!
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if (self.textField.text ?? "") == "" {
            self.presentAlertWithOk(title: nil, message: "Please enter a participant ID", actionHandler: nil)
            return false
        }
        else {
            return true
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let vc = segue.destination as? TaskTableViewController else {return}
        vc.participantID = self.textField.text
    }
    

}
