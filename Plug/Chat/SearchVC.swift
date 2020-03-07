//
//  SearchVC.swift
//  Plug
//
//  Created by changmin lee on 2020/02/29.
//  Copyright © 2020 changmin. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class SearchViewModel {
    let disposeBag = DisposeBag()
    //input
    var textinput: PublishSubject<String> = PublishSubject()
    
    //output
    var outputList: BehaviorRelay<[KidItem]> = BehaviorRelay(value: [])
    
    init() {
        guard let me = Session.me else { return }
        Observable.combineLatest(me.kids, textinput) { (kids, query) in
            if query.isEmpty {
                return kids
            } else {
                return kids.filter({ kid in
                    (kid.chatroom.name.contains(query) || kid.kid.name.contains(query) || query.isEmpty)
                }).map({ $0 })
            }
        }.bind(to: outputList).disposed(by: disposeBag)
    }
}

class SearchVC: PlugViewController {
    
    var disposeBag = DisposeBag()
    let viewModel = SearchViewModel()
    
    let sendButton = UIBarButtonItem(image: UIImage(named: "send"), style: .plain, target: self, action: nil)
    
    var parentVC: UIViewController?
    
    let tableView: UITableView = {
        let tv = UITableView()
        tv.separatorStyle = .none
        tv.register(UINib(nibName: "MultiSendCell", bundle: nil), forCellReuseIdentifier: "multi")
        tv.keyboardDismissMode = .onDrag
        return tv
    }()
    
    let searchTF: PlugTextField = {
        let tf = PlugTextField(type: .none)
        tf.placeholder = "학급 또는 이름 검색"
        tf.title = ""
        tf.lineHeight = 0
        tf.selectedLineColor = .clear
        return tf
    }()
    
    let line: UIView = {
        let v = UIView()
        v.backgroundColor = .paleGrey2
        return v
    }()
    
    let container: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        return v
    }()
    
    let cancelButton: UIButton = {
        let btn = UIButton()
        btn.setTitle("취소", for: .normal)
        btn.setTitleColor(.plugBlue, for: .normal)
        return btn
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.largeTitleDisplayMode = .never
    }
    
    override func setBinding() {
        self.searchTF.rx.text.orEmpty.bind(to: viewModel.textinput).disposed(by: disposeBag)
        
        self.cancelButton.rx.tap.subscribe(onNext: { [weak self] (_) in
            self?.dismiss(animated: true, completion: nil)
        }).disposed(by: disposeBag)
        
        self.tableView.rx.modelSelected(KidItem.self).subscribe(onNext: { [weak self] (item) in
            self?.startChat(item: item)
        }).disposed(by: disposeBag)
        
        viewModel.outputList.bind(to: tableView.rx.items) { tableView, row, item in
            let cell = tableView.dequeueReusableCell(withIdentifier: "multi", for: IndexPath(row: row, section: 0)) as! MultiSendCell
            cell.configure(name: "\(item.kid.name) 부모님", desc: item.chatroom.name, urlString: item.kid.profileURL)
            return cell
        }.disposed(by: disposeBag)
    }
    
    override func setViews() {
        self.view.backgroundColor = .white
        
        
        self.view.addSubview(container)
        container.addSubview(searchTF)
        container.addSubview(cancelButton)
        container.addSubview(line)
        self.tableView.register(UINib(nibName: "MemberCell", bundle: nil), forCellReuseIdentifier: "member")
        self.tableView.tableFooterView = UIView()
        self.tableView.rx.setDelegate(self).disposed(by: disposeBag)
        self.view.addSubview(tableView)
        
        setLayout()
    }
    
    func setLayout() {
        container.snp.makeConstraints({
            $0.top.equalTo(self.view.safeAreaLayoutGuide)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(70)
        })
        
        searchTF.snp.makeConstraints({
            $0.leading.equalToSuperview().inset(19)
            $0.trailing.equalTo(cancelButton.snp.leading).inset(19)
            $0.top.bottom.equalToSuperview().inset(4)
        })
        
        cancelButton.snp.makeConstraints({
            $0.width.equalTo(80)
            $0.top.bottom.trailing.equalToSuperview()
        })
        
        tableView.snp.makeConstraints({
            $0.top.equalTo(container.snp.bottom)
            $0.leading.trailing.bottom.equalToSuperview()
        })
        
        line.snp.makeConstraints({
            $0.bottom.left.right.equalToSuperview()
            $0.height.equalTo(1)
        })
    }
    
    func startChat(item: KidItem) {
        guard let sender = item.kid.parent,
            let userId = Session.me?.userId,
            let name = Session.me?.name else {
            return
        }
        
        let senderI = Identity(id: sender.userId, name: sender.name)
        let receiverI = Identity(id: userId, name: name)
        let chatroom = Identity(id: item.chatroom.id, name: item.chatroom.name)
        
        let identity = ChatroomIdentity(sender: senderI, receiver: receiverI, chatroom: chatroom)
        
        let storyboard = UIStoryboard(name: "Chat", bundle: nil)

        let vc = storyboard.instantiateViewController(withIdentifier: "ChatVC") as! ChatVC
        vc.identity = identity
        
        self.dismiss(animated: true) { [unowned self] in
            self.parentVC?.navigationController?.pushViewController(vc, animated: true)
        }
    }
}

extension SearchVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 72
    }
}
