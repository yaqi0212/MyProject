//
//  ViewController.m
//  AddressBook
//
//  Created by Andy on 14-10-13.
//  Copyright (c) 2014年 zhangyaqi. All rights reserved.
//

#import "ViewController.h"
#import <AddressBook/AddressBook.h>
#import "THContact.h"
#import "pinyin.h"

@interface ViewController ()
{
    NSString * str;
}
@property (nonatomic, assign) ABAddressBookRef addressBookRef;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    //读取所有联系人
    CFErrorRef error = NULL;

    _addressBookRef = ABAddressBookCreateWithOptions(NULL, &error);

    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    [self.tableView registerNib:[UINib nibWithNibName:@"THContactPickerTableViewCell" bundle:nil] forCellReuseIdentifier:@"ContactCell"];
    
    [self.view addSubview:self.tableView];
    
    ABAddressBookRequestAccessWithCompletion(self.addressBookRef, ^(bool granted, CFErrorRef error) {
        if (granted) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self getContactsFromAddressBook];
            });
        } else {
            // TODO: Show alert
        }
    });

}
-(void)getContactsFromAddressBook
{
    CFErrorRef error = NULL;
    self.contacts = [[NSMutableArray alloc]init];
    
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, &error);
    if (addressBook) {
        NSArray *allContacts = (__bridge_transfer NSArray*)ABAddressBookCopyArrayOfAllPeople(addressBook);
        NSMutableArray *mutableContacts = [NSMutableArray arrayWithCapacity:allContacts.count];
        
        NSUInteger i = 0;
        for (i = 0; i<[allContacts count]; i++)
        {
            THContact *contact = [[THContact alloc] init];
            ABRecordRef contactPerson = (__bridge ABRecordRef)allContacts[i];
            contact.recordId = ABRecordGetRecordID(contactPerson);
//            NSLog(@"%d",contact.recordId);
            // Get first and last names
            NSString *firstName = (__bridge_transfer NSString*)ABRecordCopyValue(contactPerson, kABPersonFirstNameProperty);
            NSString *lastName = (__bridge_transfer NSString*)ABRecordCopyValue(contactPerson, kABPersonLastNameProperty);
            
            // Set Contact properties
            contact.firstName = firstName;
            contact.lastName = lastName;
            
           //读取middlename拼音音标
            // Get mobile number
            ABMultiValueRef phonesRef = ABRecordCopyValue(contactPerson, kABPersonPhoneProperty);
            contact.phone = [self getMobilePhoneProperty:phonesRef];
            if(phonesRef) {
                CFRelease(phonesRef);
            }
            
            // Get image if it exists
            NSData  *imgData = (__bridge_transfer NSData *)ABPersonCopyImageData(contactPerson);
            contact.image = [UIImage imageWithData:imgData];
            if (!contact.image) {
                contact.image = [UIImage imageNamed:@"icon-avatar-60x60"];
            }
            if (contact.phone) {
                
//                NSMutableDictionary *phoneDic = [[NSMutableDictionary alloc] init];
//                phoneDic =[NSMutableDictionary dictionaryWithObjectsAndKeys:contact.fullName,@"name",contact.phone,@"phone", nil];
//                [mutableContacts addObject:phoneDic];
                
                NSLog(@"%@:%@",contact.fullName,contact.phone);
                [mutableContacts addObject:contact];

            }
        }
        
        if(addressBook) {
            CFRelease(addressBook);
        }
        
        self.contacts = [NSMutableArray arrayWithArray:mutableContacts];
        NSLog(@"%lu",(unsigned long)self.contacts.count);

//        self.filteredContacts = self.contacts;
        NSString *sectionName;
        NSMutableDictionary *contactNameDic = [[NSMutableDictionary alloc] init];
        NSMutableArray *sectionArray = [[NSMutableArray alloc] init];
        for (int i = 0; i < ALPHA.length; i++) [sectionArray addObject:[NSMutableArray array]];

        for (THContact *contact in self.contacts)
        {
            NSString *string = contact.fullName;
            if([self searchResult:string searchText:@"曾"])
                sectionName = @"Z";
            else if([self searchResult:string searchText:@"解"])
                sectionName = @"X";
            else if([self searchResult:string searchText:@"仇"])
                sectionName = @"Q";
            else if([self searchResult:string searchText:@"朴"])
                sectionName = @"P";
            else if([self searchResult:string searchText:@"查"])
                sectionName = @"Z";
            else if([self searchResult:string searchText:@"能"])
                sectionName = @"N";
            else if([self searchResult:string searchText:@"乐"])
                sectionName = @"Y";
            else if([self searchResult:string searchText:@"单"])
                sectionName = @"S";
            else
                sectionName = [[NSString stringWithFormat:@"%c",pinyinFirstLetter([string characterAtIndex:0])] uppercaseString];
            
            [contactNameDic setObject:string forKey:sectionName];
            NSUInteger firstLetter = [ALPHA rangeOfString:[sectionName substringToIndex:1]].location;
            
            if (firstLetter != NSNotFound) [[sectionArray objectAtIndex:firstLetter] addObject:contact];

        }
        self.filteredContacts = [NSMutableArray new];
        for (int i = 0; i<sectionArray.count; i++) {
            NSArray * array = [sectionArray objectAtIndex:i];
            for (int i = 0; i<array.count; i++) {
                THContact *contact = [array objectAtIndex:i];
                [self.filteredContacts addObject:contact];
                
            }
            
        }

        NSLog(@"%lu",(unsigned long)self.filteredContacts.count);
        [self.tableView reloadData];
    }
    else
    {
        NSLog(@"Error");
        
    }
}
-(BOOL)searchResult:(NSString *)contactName searchText:(NSString *)searchT{
	NSComparisonResult result = [contactName compare:searchT options:NSCaseInsensitiveSearch
											   range:NSMakeRange(0, searchT.length)];
	if (result == NSOrderedSame)
		return YES;
	else
		return NO;
}


- (NSString *)getMobilePhoneProperty:(ABMultiValueRef)phonesRef
{
    for (int i=0; i < ABMultiValueGetCount(phonesRef); i++)
    {
        
        CFStringRef currentPhoneValue = ABMultiValueCopyValueAtIndex(phonesRef, i);
        if (currentPhoneValue) {
            NSString *phone = (__bridge NSString *)currentPhoneValue;
            phone = [phone stringByReplacingOccurrencesOfString:@"-" withString:@""];
            phone = [phone stringByReplacingOccurrencesOfString:@" " withString:@""];

            if ([self isValidateMobile:phone]) {
                if ([[phone substringToIndex:3] isEqualToString:@"+86"])
                {
                    NSLog(@"+86");
                    phone = [phone substringFromIndex:3];

                }
                if ([[phone substringToIndex:2] isEqualToString:@"86"])
                {
                    NSLog(@"86");
                    phone = [phone substringFromIndex:2];
                    
                }
                return phone;
            }
            
        }
        if(currentPhoneValue) {
            CFRelease(currentPhoneValue);
        }
    }
    
    return nil;
}
/**
 * @brief 手机号码验证 MODIFIED BY HELENSONG
 */

-(BOOL)isValidateMobile:(NSString *)mobile
{
    //手机号以13， 15，18开头，八个 \d 数字字符
    NSString *phoneRegex = @"^((\\+86)|(86))?((13[0-9])|(15[^4,\\D])|(18[0,0-9]))\\d{8}$";
//    NSString *phoneRegex = @"^((13[0-9])|(15[^4,\\D])|(18[0,0-9]))\\d{8}$";

//    NSString *phoneRegex = @"^((\\+86)|(86))?(13)\\d{9}$";

    
    NSPredicate *phoneTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@",phoneRegex];
    return [phoneTest evaluateWithObject:mobile];
}
#pragma mark - UITableView Delegate and Datasource functions

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.filteredContacts.count;
}

- (CGFloat)tableView: (UITableView*)tableView heightForRowAtIndexPath: (NSIndexPath*) indexPath {
    return 70;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    // Get the desired contact from the filteredContacts array
    THContact *contact = [self.filteredContacts objectAtIndex:indexPath.row];

    // Initialize the table view cell
    NSString *cellIdentifier = @"ContactCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    // Get the UI elements in the cell;
    UILabel *contactNameLabel = (UILabel *)[cell viewWithTag:101];
    UILabel *mobilePhoneNumberLabel = (UILabel *)[cell viewWithTag:102];
    
    // Assign values to to US elements
    contactNameLabel.text       = [contact fullName];
    mobilePhoneNumberLabel.text = contact.phone;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    //    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    // This uses the custom cellView
    // Set the custom imageView
    THContact *user = [self.filteredContacts objectAtIndex:indexPath.row];
    NSLog(@"%@:%@",user.fullName,user.phone);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
