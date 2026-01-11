#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

%hook UIApplication
- (void)finishedTest:(id)arg1 extraResults:(id)arg2 {
    %orig;
    
    int len = 1024;
    // Am adăugat (unsigned char *) pentru a repara eroarea din log-ul tău
    unsigned char *data = (unsigned char *)malloc(len);
    
    if (data) {
        memset(data, 0, len);
        free(data);
    }

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"OneState Ultra" 
        message:@"Tweak-ul a fost încărcat cu succes!" 
        preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    
    // Folosim o metodă mai sigură pentru a afișa alerta pe iOS 13+
    UIWindow *keyWindow = nil;
    if (@available(iOS 13.0, *)) {
        for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive) {
                for (UIWindow *window in scene.windows) {
                    if (window.isKeyWindow) {
                        keyWindow = window;
                        break;
                    }
                }
            }
        }
    }
    
    [keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
}
%end
