//
//  AwfulForumsList.m
//  Awful
//
//  Created by Sean Berry on 7/27/10.
//  Copyright 2010 Regular Berry Software LLC. All rights reserved.
//

#import "AwfulForumsListController.h"
#import "AwfulThreadListController.h"
#import "AwfulAppDelegate.h"
#import "AwfulBookmarksController.h"
#import "AwfulForum.h"
#import "AwfulForum+AwfulMethods.h"
#import "AwfulForumHeader.h"
#import "AwfulLoginController.h"
#import "AwfulSettings.h"
#import "AwfulUser.h"
#import "AwfulParentForumCell.h"

@interface AwfulForumsListController ()

@property (nonatomic, strong) IBOutlet AwfulForumHeader *headerView;

@end

@implementation AwfulForumsListController

#pragma mark - Initialization

@synthesize headerView = _headerView;


#pragma mark - View lifecycle

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"ThreadList"]) {
        NSIndexPath *selected = (NSIndexPath*)sender;
        AwfulThreadListController *list = (AwfulThreadListController *)segue.destinationViewController;
        list.forum = [self.fetchedResultsController objectAtIndexPath:selected];
    }
}

-(void) awakeFromNib {
      
    [self setEntityName:@"AwfulForum"
              predicate:@"category != nil and (children.@count >0 or parentForum.expanded = YES)"
                   sort: [NSArray arrayWithObjects:
                          [NSSortDescriptor sortDescriptorWithKey:@"category.index" ascending:YES],
                          [NSSortDescriptor sortDescriptorWithKey:@"index" ascending:YES],
                          nil]
             sectionKey:@"category.index"
     ];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(toggleExpandForumCell:) 
                                                 name:AwfulToggleExpandForum
                                               object:nil
     ];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.navigationController setToolbarHidden:YES];
    
    self.tableView.separatorColor = [UIColor colorWithRed:0.75 green:0.75 blue:0.75 alpha:1.0];
}



- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setToolbarHidden:YES];
    
    [self.navigationItem.leftBarButtonItem setTintColor:[UIColor colorWithRed:46.0/255 green:146.0/255 blue:190.0/255 alpha:1.0]];
    
   // if(IsLoggedIn() && [self.forums count] == 0) {
     //   [self refresh];
    //} else if([self.tableView numberOfSections] == 0 && IsLoggedIn()) {
    //    [self.tableView reloadData];
   // }
}

-(void)finishedRefreshing
{
    [super finishedRefreshing];
}

- (void)refresh
{
    [super refresh];
    [self.networkOperation cancel];
    self.networkOperation = [[AwfulHTTPClient sharedClient] forumsListOnCompletion:^(NSMutableArray *forums) {
        
        [self finishedRefreshing];
        
    } onError:^(NSError *error) {
        [self finishedRefreshing];
        [ApplicationDelegate requestFailed:error];
    }];
}

-(void)stop
{
    [self.networkOperation cancel];
    [self finishedRefreshing];
}

#pragma mark - Table view data source
/*

- (void)tableView:(UITableView *)tableView
  willDisplayCell:(UITableViewCell *)cell
forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // need to set background color here to make it work on the disclosure indicator
    AwfulForumSection *section = [self getForumSectionAtIndexPath:indexPath];
    AwfulForumCell *forumCell = (AwfulForumCell *)cell;
    if (section.totalAncestors > 1) {
        UIColor *gray = [UIColor colorWithRed:235.0/255 green:235.0/255 blue:236.0/255 alpha:1.0];
        cell.backgroundColor = gray;
        forumCell.titleLabel.backgroundColor = gray;
    } else {
        cell.backgroundColor = [UIColor whiteColor];
        forumCell.titleLabel.backgroundColor = [UIColor whiteColor];
    }
}

*/
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    [[NSBundle mainBundle] loadNibNamed:@"AwfulForumHeaderView" owner:self options:nil];
    AwfulForumHeader *header = self.headerView;
    self.headerView = nil;
    
    header.titleLabel.text = [self.fetchedResultsController.sectionIndexTitles objectAtIndex:section];
    return header;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 30;
}


- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"AwfulParentForumCell";
    UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}
 

-(void) configureCell:(AwfulParentForumCell*)cell atIndexPath:(NSIndexPath*)indexPath {
    AwfulForum* forum = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.forum = forum;
    cell.textLabel.text = forum.name;
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    cell.detailTextLabel.text = forum.desc;
    cell.detailTextLabel.numberOfLines = 0;
    [(AwfulParentForumCell*)cell setIsExpanded:forum.expandedValue];
    
    if (forum.parentForum != nil) {
        cell.indentationLevel = 2;
        cell.textLabel.font = [UIFont boldSystemFontOfSize:15];
        cell.textLabel.font = [UIFont boldSystemFontOfSize:14];
        cell.detailTextLabel.text = forum.parentForum.name;
        cell.imageView.image = nil;
    }
}

-(CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    AwfulForum* forum = [self.fetchedResultsController objectAtIndexPath:indexPath];
    int width = tableView.frame.size.width - 20 - 50;

    CGSize textSize = {0, 0};
    CGSize detailSize = {0, 0};
    int height = 44;
    
    textSize = [forum.name sizeWithFont:[UIFont boldSystemFontOfSize:16]
                         constrainedToSize:CGSizeMake(width, 4000) 
                             lineBreakMode:UILineBreakModeWordWrap];
    if(forum.desc)
        detailSize = [forum.desc sizeWithFont:[UIFont systemFontOfSize:15] 
                             constrainedToSize:CGSizeMake(width, 4000) 
                                 lineBreakMode:UILineBreakModeWordWrap];
    
    height = 10 + textSize.height + detailSize.height;
    
    return (MAX(height,50));
}

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self performSegueWithIdentifier:@"ThreadList" sender:indexPath];
}

#pragma mark - Forums

-(void) toggleExpandForumCell:(NSNotification*)msg {
    AwfulParentForumCell* cell = msg.object;
    BOOL toggle = [[msg.userInfo objectForKey:@"toggle"] boolValue];
    
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    AwfulForum* forum = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    forum.expandedValue = toggle;
    NSLog(@"pre count: %i", [[[self.fetchedResultsController sections] objectAtIndex:indexPath.section] numberOfObjects]);
    [ApplicationDelegate saveContext];
    
    
    NSMutableArray* rows = [NSMutableArray new];
    for (int i=indexPath.row+1; i<=indexPath.row+forum.children.count; i++) {
        [rows addObject:[NSIndexPath indexPathForRow:i inSection:indexPath.section]];
    }
    
    [self.tableView beginUpdates];

    [self.fetchedResultsController performFetch:nil];
    NSLog(@"post count: %i", [[[self.fetchedResultsController sections] objectAtIndex:indexPath.section] numberOfObjects]);
    if (toggle) 
         [self.tableView insertRowsAtIndexPaths:rows withRowAnimation:(UITableViewRowAnimationTop)];
    else
         [self.tableView deleteRowsAtIndexPaths:rows withRowAnimation:(UITableViewRowAnimationTop)];
         
    [self.tableView endUpdates];
        
}

@end

