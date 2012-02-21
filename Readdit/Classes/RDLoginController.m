//
//  RDLoginController.m
//  Readdit
//
//  Created by Samuel Sutch on 9/5/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "RDLoginController.h"
#import "RDTextInputCell.h"
#import "RDRedditClient.h"


@implementation RDLoginController

@synthesize delegate, splitController;


#pragma mark -
#pragma mark View lifecycle

/*
- (void)viewDidLoad {
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}
*/

/*
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}
*/

- (void)viewDidAppear:(BOOL)animated 
{
  [super viewDidAppear:animated];
  if (usernameField) [usernameField becomeFirstResponder];
}

/*
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}
*/
/*
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}
*/


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
  return YES;
}


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
  return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
  return 2;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView 
         cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
  NSArray *b = [[NSBundle mainBundle] loadNibNamed:
                @"RDTextInputCell" owner:nil options:nil];
  RDTextInputCell *cell = [b objectAtIndex:0];
  [cell addSubview:cell.textField];
  cell.textField.frame = CGRectMake(150, 8, 350, 32);
  cell.textLabel.font = [UIFont boldSystemFontOfSize:17];
  cell.delegate = self;
  if (indexPath.row == 0) {
    cell.textLabel.text = @"Username";
    usernameField = cell.textField;
  } else {
    cell.textLabel.text = @"Password";
    cell.textField.secureTextEntry = YES;
    cell.textField.returnKeyType = UIReturnKeyGo;
    passwordField = cell.textField;
  }
  return cell;
}

- (void)nextFieldFromInputCell:(RDTextInputCell *)cell
{
  if ([cell.textLabel.text hasPrefix:@"Username"]) {
    if (passwordField) [passwordField becomeFirstResponder];
  } else {
    if (HUD) [HUD release];
    HUD = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
    HUD.labelText = @"Loading...";
    [self.navigationController.view addSubview:HUD];
    [HUD show:YES];
    [[[RDRedditClient sharedClient] loginUsername:usernameField.text password:
      passwordField.text] addCallback:callbackTS(self, loggedIn:)];
  }
}

- (id)loggedIn:(NSString *)status
{
  if ([status isEqual:@"success"]) {
    HUD.labelText = @"Success";
    if (delegate && [delegate respondsToSelector:@selector(loginControllerLoggedIn:)])
      [delegate performSelector:@selector(loginControllerLoggedIn:) withObject:usernameField.text];
  } else {
    HUD.labelText = @"Incorrect Password";
    if (delegate && [delegate respondsToSelector:@selector(loginControllerFailedLogin:)])
      [delegate performSelector:@selector(loginControllerFailedLogin:) withObject:nil];
  }
  [[NSRunLoop currentRunLoop] runUntilDate:
   [NSDate dateWithTimeIntervalSinceNow:0.5]];
  [HUD hide:YES];
  return status;
}

- (void) hudWasHidden
{
  [HUD removeFromSuperview];
  [HUD release];
  HUD = nil;
}

-(NSString *) tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
  if(section == 0)
    return @"Your credentials are ONLY shared with Reddit.com. We do not store these anywhere other than on your device.";
  else
    return @"";
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/


/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/


/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/


/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
  RDTextInputCell *cell = [[tableView visibleCells] objectAtIndex:indexPath.row];
  [cell.textField becomeFirstResponder];
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


#pragma mark -
#pragma mark Memory management

//- (void)didReceiveMemoryWarning {
//    // Releases the view if it doesn't have a superview.
//    [super didReceiveMemoryWarning];
//    
//    // Relinquish ownership any cached data, images, etc that aren't in use.
//}
//
//- (void)viewDidUnload {
//    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
//    // For example: self.myOutlet = nil;
//}


- (void)dealloc 
{
  [splitController release];
  [super dealloc];
}


@end

