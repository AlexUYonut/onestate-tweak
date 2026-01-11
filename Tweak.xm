#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>
#import <dlfcn.h>

// Functie universala de patch pentru simboluri
void patch_symbol(const char *symbolName) {
    void *symbol = dlsym(RTLD_DEFAULT, symbolName);
    if (symbol) {
        uint32_t patch = 0xD65F03C0; // Instructiunea de activare
        vm_protect(mach_task_self(), (vm_address_t)symbol, sizeof(patch), false, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY);
        memcpy(symbol, &patch, sizeof(patch));
        vm_protect(mach_task_self(), (vm_address_t)symbol, sizeof(patch), false, VM_PROT_READ | VM_PROT_EXECUTE);
        NSLog(@"[OneState] %s a fost activat!", symbolName);
    }
}

%hook UIApplication
- (void)finishedTest:(id)arg1 extraResults:(id)arg2 {
    %orig;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(60 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        // 1. Activam AIMBOT dupa numele functiei
        patch_symbol("GetLocalSpaceAim");
        
        // 2. Activam ESP dupa numele functiei
        patch_symbol("WorldToScreen"); 

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"OneState Ultra" 
            message:@"Ambele functii (Aim & ESP) au fost procesate prin nume." 
            preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        
        UIWindow *window = [UIApplication sharedApplication].windows.firstObject;
        [window.rootViewController presentViewController:alert animated:YES completion:nil];
    });
}
%end
