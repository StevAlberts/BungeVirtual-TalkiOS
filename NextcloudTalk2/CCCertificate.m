//
//  CCCertificate.m
//  Nextcloud iOS
//
//  Created by Marino Faggiana on 10/08/16.
//  Copyright (c) 2017 TWS. All rights reserved.
//
//  Author Marino Faggiana <m.faggiana@twsweb.it>
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

#import "CCCertificate.h"

#import <openssl/x509.h>
#import <openssl/bio.h>
#import <openssl/err.h>
#import <openssl/pem.h>

#import "NCAppBranding.h"

@implementation CCCertificate

NSString *const appCertificates = @"Library/Application Support/Certificates";

//Singleton
+ (id)sharedManager {
    static CCCertificate *CCCertificate = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        CCCertificate = [[self alloc] init];
    });
    return CCCertificate;
}

static SecCertificateRef SecTrustGetLeafCertificate(SecTrustRef trust)
// Returns the leaf certificate from a SecTrust object (that is always the 
// certificate at index 0).
{
    SecCertificateRef   result;
    
    assert(trust != NULL);
    
    if (SecTrustGetCertificateCount(trust) > 0) {
        result = SecTrustGetCertificateAtIndex(trust, 0);
        assert(result != NULL);
    } else {
        result = NULL;
    }
    return result;
}

- (BOOL)checkTrustedChallenge:(NSURLAuthenticationChallenge *)challenge
{
    BOOL trusted = NO;
    SecTrustRef trust;
    NSURLProtectionSpace *protectionSpace;
    
    protectionSpace = [challenge protectionSpace];
    trust = [protectionSpace serverTrust];
        
    if(trust != nil) {
        [self saveCertificate:trust withName:@"tmp.der"];
        NSString *localCertificatesFolder = [self getDirectoryCerificates];
        NSArray* listCertificateLocation = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:localCertificatesFolder error:NULL];
        
        for (int i = 0 ; i < [listCertificateLocation count] ; i++) {
            NSString *currentLocalCertLocation = [NSString stringWithFormat:@"%@/%@",localCertificatesFolder,[listCertificateLocation objectAtIndex:i]];
            NSString *tempCertLocation = [NSString stringWithFormat:@"%@/%@",localCertificatesFolder,@"tmp.der"];
            NSFileManager *fileManager = [ NSFileManager defaultManager];
            
            if(![currentLocalCertLocation isEqualToString:tempCertLocation] &&
               [fileManager contentsEqualAtPath:tempCertLocation andPath:currentLocalCertLocation]) {
                
                NSLog(@"Certificated matched with one saved previously.");
                trusted = YES;
            }
        }
    } else {
        trusted = NO;
    }
    
    return trusted;
}

- (void)saveCertificate:(SecTrustRef)trust withName:(NSString *)certName
{
    SecCertificateRef currentServerCert = SecTrustGetLeafCertificate(trust);
    
    CFDataRef data = SecCertificateCopyData(currentServerCert);
    X509 *x509cert = NULL;
    if (data) {
        BIO *mem = BIO_new_mem_buf((void *)CFDataGetBytePtr(data), (int)CFDataGetLength(data));
        x509cert = d2i_X509_bio(mem, NULL);
        BIO_free(mem);
        CFRelease(data);
        
        if (!x509cert) {
            
            NSLog(@"[LOG] OpenSSL couldn't parse X509 Certificate");
            
        } else {
            
            NSString *localCertificatesFolder = [self getDirectoryCerificates];
            
            certName = [NSString stringWithFormat:@"%@/%@",localCertificatesFolder,certName];
            
            if ([[NSFileManager defaultManager] fileExistsAtPath:certName]) {
                NSError *error;
                [[NSFileManager defaultManager] removeItemAtPath:certName error:&error];
            }
            
            FILE *file;
            file = fopen([certName UTF8String], "w");
            if (file) {
                PEM_write_X509(file, x509cert);
            }
            fclose(file);
        }
    
    } else {
        
        NSLog(@"[LOG] Failed to retrieve DER data from Certificate Ref");
    }
    
    //Free
    X509_free(x509cert);
}

- (void)presentViewControllerCertificateWithTitle:(NSString *)title viewController:(UIViewController *)viewController delegate:(id)delegate
{
    if (![viewController isKindOfClass:[UIViewController class]])
        return;
    
    _delegate = delegate;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:NSLocalizedString(@"Do you want to connect to the server anyway?", nil)  preferredStyle:UIAlertControllerStyleAlert];
        
        [alertController addAction: [UIAlertAction actionWithTitle:NSLocalizedString(@"Yes", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            
            [[CCCertificate sharedManager] acceptCertificate];
            
            if([self.delegate respondsToSelector:@selector(trustedCerticateAccepted)])
                [self.delegate trustedCerticateAccepted];
        }]];
        
        [alertController addAction: [UIAlertAction actionWithTitle:NSLocalizedString(@"No", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            
            if([self.delegate respondsToSelector:@selector(trustedCerticateDenied)])
                [self.delegate trustedCerticateDenied];
        }]];
        
        [viewController presentViewController:alertController animated:YES completion:nil];
    });
}

- (BOOL)acceptCertificate
{
    NSString *localCertificatesFolder = [self getDirectoryCerificates];
    NSError *error;
    NSFileManager *fm = [[NSFileManager alloc] init];
    NSTimeInterval dateCertificate = [[NSDate date] timeIntervalSince1970];
    NSString *currentCertLocation = [NSString stringWithFormat:@"%@/%f.der",localCertificatesFolder, dateCertificate];
    
    NSLog(@"[LOG] currentCertLocation: %@", currentCertLocation);
    
    if(![fm moveItemAtPath:[NSString stringWithFormat:@"%@/%@",localCertificatesFolder, @"tmp.der"] toPath:currentCertLocation error:&error]) {
        
        NSLog(@"[LOG] Error: %@", [error localizedDescription]);
        return NO;
        
    }
    
    return YES;
}

- (NSString *)getDirectoryCerificates
{
    NSURL *dirGroup = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:groupIdentifier];
    
    NSString *dir = [[dirGroup URLByAppendingPathComponent:appCertificates] path];
    if (![[NSFileManager defaultManager] fileExistsAtPath:dir])
        [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
    
    return dir;
}

@end
