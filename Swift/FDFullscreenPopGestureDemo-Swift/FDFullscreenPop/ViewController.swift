//
//  ViewController.swift
//  FDFullscreenPop
//
//  Created by Yilei on 9/3/17.
//  Copyright © 2017 lionhylra. All rights reserved.
//

import UIKit

var i = 0

class ViewController: UIViewController {

    @IBOutlet weak var label: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        label.text = "\(i)"
        defer {i += 1}
        
        fd.interactivePopMaxAllowedInitialDistanceToLeftEdge = 20
        
        let n = Int.random(range: 0..<2)
        if n == 0 {
            fd.prefersNavigationBarHidden = true
            label.text! += " no nav"
//            fd.interactivePopDisabled = true
        } else {
            fd.prefersNavigationBarHidden = false
        }
        
        self.title = label.text
    }


    @IBAction func prev(_ sender: UIButton) {
        _ = navigationController?.popViewController(animated: true)
    }

    @IBAction func next(_ sender: UIButton) {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "VC")
        navigationController?.pushViewController(vc, animated: true)
        
    }
}

