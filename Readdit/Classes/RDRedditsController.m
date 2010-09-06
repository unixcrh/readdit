//
//  RootViewController.m
//  Readdit
//
//  Created by Samuel Sutch on 9/5/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import "RDRedditsController.h"
#import "MGSplitViewController.h"
#import "RDBrowserController.h"
#import "RDRedditClient.h"
#import "RDLoginController.h"
#import "YMRefreshView.h"


@interface RDRedditsController (PrivateParts)

- (void)privateInit;

@end


@implementation RDRedditsController

@synthesize detailViewController, splitController, username;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
    [self privateInit];
  }
  return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
  if ((self = [super initWithCoder:aDecoder])) {
    [self privateInit];
  }
  return self;
}

- (void)privateInit
{
  self.actionTableViewHeaderClass = [YMRefreshView class];
  // TODO: multi-user support
  username = [PREF_KEY(@"username") retain];
  performingInitialSync = NO;
  reddits = [EMPTY_ARRAY retain];
  builtins = [array_(array_(@"Front Page", @"/"), array_(@"All", @"/r/all/"),
                    array_(@"Friends", @"/r/friends/"), array_(@"Submitted", @"/user/$username/submitted/"),
                    array_(@"Liked", @"/user/$username/liked/"), array_(@"Disliked", @"/user/$username/disliked/"),
                     array_(@"Hidden", @"/user/$username/hidden/")) retain];
}

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad 
{
  [super viewDidLoad];
  self.clearsSelectionOnViewWillAppear = NO;
  self.contentSizeForViewInPopover = CGSizeMake(320.0, 600.0);
}

- (void)viewWillAppear:(BOOL)animated 
{
  [super viewWillAppear:animated];
  [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated 
{
  [super viewDidAppear:animated];
  if (![[[RDRedditClient sharedClient] accounts] count]) {
    RDLoginController *login = [[[RDLoginController alloc] initWithStyle:
                                 UITableViewStyleGrouped] autorelease];
    login.splitController = self.splitController;
    login.delegate = self;
    login.title = @"Login";
    UINavigationController *nav = [[[UINavigationController alloc] 
                                initWithRootViewController:login] autorelease];
    nav.modalPresentationStyle = UIModalPresentationFormSheet;
    [self.splitController presentModalViewController:nav animated:YES];
  } else {
    if (username) {
      id l = PREF_KEY([username stringByAppendingString:@"redditslastupdated"]);
      if (l) {
        NSDate *lastUpdated = [NSDate dateWithTimeIntervalSince1970:[l intValue]];
        [(YMRefreshView *)self.refreshHeaderView setLastUpdatedDate:lastUpdated];
      }
    }
    if (!performingInitialSync) {
      performingInitialSync = YES;
      [self showReloadAnimationAnimated:YES];
      [[[RDRedditClient sharedClient] cachedSubredditsForUsername:username] 
       addBoth:callbackTS(self, _gotCachedSubreddits:)];
    }
  } 
}

- (void)reloadTableViewDataSource
{
  if (performingInitialSync) return;
}

- (id)_gotCachedSubreddits:(id)r
{
  if ([r isKindOfClass:[NSArray class]]) {
    reddits = [r retain];
    NSLog(@"gotCachedSubreddits: %d", [r count]);
  } else {
    NSLog(@"cachedSubreddits Miss %@", r);
  }
  [self.tableView reloadData];
  [[[RDRedditClient sharedClient] subredditsForUsername:username] 
   addBoth:callbackTS(self, _gotSubreddits:)];
  return r;
}

- (id)_gotSubreddits:(id)r
{
  NSLog(@"gotSubreddits %d", [r count]);
  if (isDeferred(r)) return [r addBoth:callbackTS(self, _gotSubreddits:)];
  NSDate *d = [NSDate date];
  PREF_SET([username stringByAppendingString:@"redditslastupdated"], nsni([d timeIntervalSince1970]));
  PREF_SYNCHRONIZE;
  [(YMRefreshView *)self.refreshHeaderView setLastUpdatedDate:d];
  if (reddits) [reddits release];
  reddits = [r retain];
  [self dataSourceDidFinishLoadingNewData];
  performingInitialSync = NO;
  [self.tableView reloadData];
  return r;
}

- (void)loginControllerLoggedIn:(id)arg
{
  username = [arg copy];
  [self.splitController dismissModalViewControllerAnimated:YES];
  performingInitialSync = YES;
  [self showReloadAnimationAnimated:YES];
  [[[RDRedditClient sharedClient] cachedSubredditsForUsername:username] 
   addBoth:callbackTS(self, _gotCachedSubreddits:)];
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

// Ensure that the view controller supports rotation and that the split view can therefore show in both portrait and landscape.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)aTableView 
{
  return 2;
}


- (NSInteger)tableView:(UITableView *)aTableView 
 numberOfRowsInSection:(NSInteger)section 
{
  return section == 0 ? [builtins count] : [reddits count];
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
  return section == 0 ? nil : @"Subscribed";
}


- (UITableViewCell *)tableView:(UITableView *)tableView 
         cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
  static NSString *ident = @"SubredditCell1";

  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ident];
  if (cell == nil) {
    cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                   reuseIdentifier:ident] autorelease];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
  }
  if (indexPath.section == 0) {
    cell.textLabel.text = [[builtins objectAtIndex:indexPath.row] objectAtIndex:0];
    cell.detailTextLabel.text = nil;
  } else {
    NSDictionary *s = [[reddits objectAtIndex:indexPath.row] objectForKey:@"data"];
    cell.textLabel.text = [s objectForKey:@"title"];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ - %@ subscribers", 
                               [s objectForKey:@"url"], [s objectForKey:@"subscribers"]];
  }
  return cell;
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

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    /*
     When a row is selected, set the detail view controller's detail item to the item associated with the selected row.
     */
    detailViewController.detailItem = [NSString stringWithFormat:@"Row %d", indexPath.row];
}


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}


- (void)dealloc 
{
  [username release];
  [builtins release];
  [reddits release];
  [detailViewController release];
  [super dealloc];
}


@end

