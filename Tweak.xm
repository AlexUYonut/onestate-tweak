#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <mach-o/dyld.h>

void patch_offset(uintptr_t offset, uint32_t data) {
    uintptr_t address = _dyld_get_image_vmaddr_slide(0) + offset;
    vm_protect(mach_task_self(), (vm_address_t)address, sizeof(data), false, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY);
    memcpy((void *)address, &data, sizeof(data));
    vm_protect(mach_task_self(), (vm_address_t)address, sizeof(data), false, VM_PROT_READ | VM_PROT_EXECUTE);
}

%hook UIApplication
- (void)finishedTest:(id)arg1 extraResults:(id)arg2 {
    %orig;
    
    // FIXUL pentru eroarea din Imaginea 11:
    int len = 1024;
    unsigned char *data = (unsigned char *)malloc(len); 
    if (data) {
        memset(data, 0, len);
        free(data);
    }

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // OFFSETURILE TALE
        patch_offset(0x1234567, 0xD2800020); // Aimbot
        patch_offset(0x7654321, 0xD2800020); // ESP

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"OneState Ultra" 
            message:@"Hacks Activated!" 
            preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        
        // Rezolvă eroarea din Imaginea 10 (keyWindow)
        UIWindow *window = [UIApplication sharedApplication].windows.firstObject;
        [window.rootViewController presentViewController:alert animated:YES completion:nil];
    });
}
%end
