/* SilabasController */

#import <Cocoa/Cocoa.h>

@class SScribe;

@interface SilabasController : NSObject
{
    IBOutlet NSPopUpButton *grammarPopUp;
    IBOutlet NSTextView *inputTextView;
	IBOutlet NSTextView *outputTextView;
	
	SScribe *_scribe;
	NSDictionary *_grammar;
}
// Actions
- (IBAction)syllabify:(id)sender;

// Accessors
- (NSAttributedString*)textForTranscription;

// Utility Methods
- (void)loadGrammar;
- (void)populateGrammarPopUp;

// Debugging Helpers
- (void)displayString:(NSString*)message;
- (void)displayAttributedString:(NSMutableAttributedString*)message;
- (void)appendString:(NSString*)message;
- (void)appendAttributedString:(NSMutableAttributedString*)message;
@end
