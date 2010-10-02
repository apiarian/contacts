#import <Foundation/Foundation.h>
#import <AddressBook/AddressBook.h>

void usage(const char * arg0) {
  printf("Usage:\n");
  printf("%s [-h] [-f formatstring] [name to search]\n\n",arg0);
  printf("  -h prints this usage and exits\n\n");
  printf("  the name may be one of the following:\n");
  printf("    First\n");
  printf("    Last\n");
  printf("    First Last\n");
  printf("    Last First\n\n");
  printf("  the format string may include one of the following:\n");
  printf("    %%f - first name\n");
  printf("    %%l - last name\n");
  printf("    %%b - birthday\n");
}

int main (int argc, const char * argv[]) {
  NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
  
  // insert code here...
  NSDictionary *formatBindings = [NSDictionary dictionaryWithObjectsAndKeys: 
                                  kABFirstNameProperty, @"%f",
                                  kABLastNameProperty, @"%l",
                                  kABBirthdayProperty, @"%b",
                                  nil];
  
  NSMutableArray *args = [NSMutableArray arrayWithCapacity:argc];
  for (int i = 0; i < argc; i++) {
    [args addObject:[NSString stringWithUTF8String:argv[i]]];
  }
  NSString *formatString = @"%f %l %b";
  for (int i = 1; i < [args count]; i++) {
    if ([[args objectAtIndex:i] isEqualToString:@"-h"]) {
      usage(argv[0]);
      [pool drain];
      return 0;
    }
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
    usage(argv[0]);
    [pool drain];
    return 1;
  }
  
  NSArray *people = [ab recordsMatchingSearchElement:searchConstruct];
  NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
  for (ABRecord *person in people) {
    NSMutableString *stringToPrint = [NSMutableString stringWithString:formatString];
    for (NSString *key in formatBindings) {
      if ([formatString rangeOfString:key].length == 0) {
        continue;
      }
      NSString *currentProperty = [formatBindings objectForKey:key];
      ABPropertyType currentPropertyType = [ABPerson typeOfProperty:currentProperty];
      NSString *replacementString;
      if (currentPropertyType == kABStringProperty) {
        replacementString = [person valueForProperty:currentProperty];
      } else if ([ABPerson typeOfProperty:currentProperty] == kABDateProperty) {
        NSDateComponents *date = [gregorian components:(NSMonthCalendarUnit|NSDayCalendarUnit|NSYearCalendarUnit)
                                              fromDate:[person valueForProperty:currentProperty]];
        replacementString = [NSString stringWithFormat:@"%d/%d/%d",[date month],[date day],[date year]];
      } else {
        replacementString = key;
      }
      [stringToPrint replaceOccurrencesOfString:key 
                                     withString:replacementString
                                        options:NSLiteralSearch
                                          range:NSMakeRange(0, [stringToPrint length])];
    }
    printf("%s\n",[stringToPrint UTF8String]);
  }
  
  [pool drain];
  return 0;
}
