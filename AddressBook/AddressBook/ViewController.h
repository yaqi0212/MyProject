//
//  ViewController.h
//  AddressBook
//
//  Created by Andy on 14-10-13.
//  Copyright (c) 2014年 zhangyaqi. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray *contacts;
@property (nonatomic, strong) NSMutableArray *filteredContacts;
@end
