#import <Foundation/Foundation.h>
#import <AddressBook/AddressBook.h>

void usage(const char * arg0) {
  printf("Usage:\n");
  printf("%s [-f formatstring] [name to search]\n",arg0);
}

int main (int argc, const char * argv[]) {
  NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
  
  // insert code here...
//  usage(argv[0]);
//  [pool drain];
//  return 0;
  
  NSMutableArray *args = [NSMutableArray arrayWithCapacity:argc];
  for (int i = 0; i < argc; i++) {
    [args addObject:[NSString stringWithUTF8String:argv[i]]];
  }
  NSString *formatString = @"%f %l %b";
  for (int i = 1; i < [args count]; i++) {
    if ([[args objectAtIndex:i] isEqualToString:@"-f"]) {
      formatString = [args objectAtIndex:i+1];
    }
  }
  NSArray *searchStrings = [[args lastObject] componentsSeparatedByString:@" "];
  
  ABAddressBook *ab = [ABAddressBook addressBook];
  ABSearchElement *searchConstruct;
  if ([searchStrings count] == 1) {
    ABSearchElement *firstNameSearch = [ABPerson searchElementForProperty:kABFirstNameProperty
                                                                    label:nil
                                                                      key:nil 
                                                                    value:[searchStrings lastObject]
                                                               comparison:kABEqualCaseInsensitive];
    ABSearchElement *lastNameSearch = [ABPerson searchElementForProperty:kABLastNameProperty
                                                                   label:nil 
                                                                     key:nil
                                                                   value:[searchStrings lastObject]
                                                              comparison:kABEqualCaseInsensitive];
    searchConstruct = [ABSearchElement searchElementForConjunction:kABSearchOr
                                                          children:[NSArray arrayWithObjects:firstNameSearch, lastNameSearch, nil]];
  } else if ([searchStrings count] == 2) {
    ABSearchElement *firstFirst = [ABPerson searchElementForProperty:kABFirstNameProperty
                                                               label:nil 
                                                                 key:nil
                                                               value:[searchStrings objectAtIndex:0]
                                                          comparison:kABEqualCaseInsensitive];
    ABSearchElement *firstSecond = [ABPerson searchElementForProperty:kABFirstNameProperty
                                                                label:nil 
                                                                  key:nil
                                                                value:[searchStrings objectAtIndex:1]
                                                           comparison:kABEqualCaseInsensitive];
    ABSearchElement *lastFirst = [ABPerson searchElementForProperty:kABLastNameProperty
                                                              label:nil 
                                                                key:nil
                                                              value:[searchStrings objectAtIndex:0]
                                                         comparison:kABEqualCaseInsensitive];
    ABSearchElement *lastSecond = [ABPerson searchElementForProperty:kABLastNameProperty
                                                               label:nil 
                                                                 key:nil
                                                               value:[searchStrings objectAtIndex:1]
                                                          comparison:kABEqualCaseInsensitive];
    ABSearchElement *fl = [ABSearchElement searchElementForConjunction:kABSearchAnd
                                                              children:[NSArray arrayWithObjects:firstFirst, lastSecond, nil]];
    ABSearchElement *lf = [ABSearchElement searchElementForConjunction:kABSearchAnd 
                                                              children:[NSArray arrayWithObjects:lastFirst, firstSecond, nil]];
    searchConstruct = [ABSearchElement searchElementForConjunction:kABSearchOr
                                                          children:[NSArray arrayWithObjects:fl, lf, nil]];
  } else {
    printf("Only [First] or [Last] or [First Last] or [Last First] name constructs are supported.\n");
    [pool drain];
    return 1;
  }
  
  NSArray *people = [ab recordsMatchingSearchElement:searchConstruct];
  NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
  for (ABRecord *person in people) {
    NSDateComponents *birthday = [gregorian components:(NSMonthCalendarUnit|NSDayCalendarUnit|NSYearCalendarUnit) 
                                              fromDate:[person valueForProperty:kABBirthdayProperty]];
    printf("%s %s %s\n",
           [[person valueForProperty:kABFirstNameProperty] UTF8String],
           [[person valueForProperty:kABLastNameProperty] UTF8String],
           [[NSString stringWithFormat:@"%d/%d/%d",[birthday month], [birthday day], [birthday year]] UTF8String]);
  }
  
  [pool drain];
  return 0;
}
