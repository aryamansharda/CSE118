//
//  PatientListTableViewController.m
//  MyoMD
//
//  Created by Aryaman Sharda on 10/25/16.
//  Copyright © 2016 Aryaman Sharda. All rights reserved.
//

#import "PatientDetailViewController.h"
#import "PatientListTableViewController.h"
#import "PatientTableViewCell.h"
#import "Patients.h" 
#import "SVProgressHUD.h"

@interface PatientListTableViewController ()

@end

@implementation PatientListTableViewController
{
    NSMutableArray *patientData;
    NSInteger index;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setNeedsStatusBarAppearanceUpdate];
    [[UINavigationBar appearance] setBarTintColor:[UIColor colorWithRed:.08 green:.474 blue:.99215 alpha:1]];
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
        self.edgesForExtendedLayout = UIRectEdgeNone;
    
    patientData = [[NSMutableArray alloc] init]; 
    
    PFQuery *query = [PFQuery queryWithClassName:@"Patients"];    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            int x = 1;
            for (PFObject *object in objects) {
                Patients *patient = [[Patients alloc] init];
                patient.patientID = object.objectId;
                patient.patientName = [object objectForKey:@"name"];
                patient.phoneNumber = [object objectForKey:@"phoneNumber"];
                patient.emailId = [object objectForKey:@"emailId"];
                patient.gender = [object objectForKey:@"gender"];
                patient.height = [[object objectForKey:@"metadata"] objectForKey:@"height"];
                patient.weight = [[object objectForKey:@"metadata"] objectForKey:@"weight"];
                patient.medications = [object objectForKey:@"medications"];
                patient.allergies = [object objectForKey:@"allergies"];
                patient.patientPhotoName = [NSString stringWithFormat:@"patient-place-holder%d.jpg", x++];
                
                NSMutableArray *examinations = [[NSMutableArray alloc] init];
                PFQuery *getExaminations = [PFQuery queryWithClassName:@"Examinations"];
                [getExaminations whereKey:@"patientID" equalTo:object.objectId];
                [getExaminations findObjectsInBackgroundWithBlock:^(NSArray *exams, NSError *examError) {
                    if (!examError) {
                        for (PFObject *ex in exams) {
                            Examinations *exam = [[Examinations alloc] init];
                            exam.examinationID = ex.objectId;
                            exam.patientID = object.objectId;
                            exam.date = [ex objectForKey:@"examinationDate"];
                            exam.gumTestResults = [ex objectForKey:@"gumTestResults"];
                            [examinations addObject:exam];
                        }
                    } else {
                        NSLog(@"Error: %@ %@", examError, [examError userInfo]);
                    }
                }];
                
                patient.examinations = examinations;
                    
                
                [patientData addObject:patient];
            }
            
            [self.tableView reloadData];
            
        } else {
            NSLog(@"Error: %@ %@", error, [error userInfo]);
        }
    }];
    
    CGRect frame = CGRectMake(0, 0, 375, 64);
    UILabel *label = [[UILabel alloc] initWithFrame:frame];
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont fontWithName:@"Montserrat-Regular" size:17.5];
    label.textAlignment = UITextAlignmentCenter;
    label.textColor = [UIColor whiteColor];
    label.text = @"PATIENTS";
    self.navigationItem.titleView = label;
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"background-social-image.png"]];

}

-(void)viewWillLayoutSubviews{
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7)
    {
        self.view.clipsToBounds = YES;
        CGRect screenRect = [[UIScreen mainScreen] bounds];
        CGFloat screenHeight = 0.0;
        if(UIDeviceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation]))
            screenHeight = screenRect.size.height;
        else
            screenHeight = screenRect.size.width;
        CGRect screenFrame = CGRectMake(0, 20, self.view.frame.size.width,screenHeight-20);
        CGRect viewFr = [self.view convertRect:self.view.frame toView:nil];
        if (!CGRectEqualToRect(screenFrame, viewFr))
        {
            self.view.frame = screenFrame;
            self.view.bounds = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
        }
    }
}

-(IBAction)dismissView:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (UIStatusBarStyle) preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (UIBarPosition)positionForBar:(id<UIBarPositioning>)bar {
    return UIBarPositionTopAttached;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [patientData count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"CellIdentifier";
    
    PatientTableViewCell *cell = (PatientTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil)
    {
        cell = [[PatientTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    Patients *patient = [patientData objectAtIndex:indexPath.row];
    cell.patientName.text = patient.patientName;
    cell.patientEmail.text = patient.emailId;
    cell.patientPhone.text = patient.phoneNumber;
    cell.patientPhoto.image = [UIImage imageNamed:patient.patientPhotoName];
    cell.patientPhoto.layer.cornerRadius = cell.patientPhoto.frame.size.width / 2;
    cell.patientPhoto.clipsToBounds = YES;

    
    return cell;
}



-(void)viewWillDisappear:(BOOL)animated {
    [SVProgressHUD dismiss];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    index = indexPath.row;
    [SVProgressHUD show];
    [self performSegueWithIdentifier:@"patientDetailView" sender:self];
}
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    
    if([segue.identifier isEqualToString:@"patientDetailView"]){
        NSLog(@"Hitting Row: %ld", (long)index);
        PatientDetailViewController *controller = (PatientDetailViewController *)segue.destinationViewController;
        controller.patient = patientData[index];
        
    }
    
    if ([segue.identifier isEqualToString:@"logOut"]) {
        [PFUser logOut];
    }
}
@end
