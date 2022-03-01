#import "TRTCCustomerCrypt.h"
#ifndef TRTC_INTERNATIONAL
#import "TXLiteAVEncodedDataProcessingListener.h"
#endif
#include <string>
#import <CommonCrypto/CommonDigest.h> // Need to import for CC_MD5 access

@implementation NSString (Extensions_MD5)
- (NSString *) md5
{
    const char *cStr = [self UTF8String];
    unsigned char result[16];
    CC_MD5( cStr, (CC_LONG)strlen(cStr), result ); // This is the md5 call
    return [NSString stringWithFormat:
            @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
    ];
}
@end

@implementation NSData (Extensions_MD5)
- (NSString*)md5
{
    unsigned char result[16];
    CC_MD5( self.bytes, (CC_LONG)self.length, result ); // This is the md5 call
    return [NSString stringWithFormat:
            @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
    ];
}
@end

#ifndef TRTC_INTERNATIONAL
class TRTCCustomerEncryptor: public liteav::ITXLiteAVEncodedDataProcessingListener {
public:
    bool didEncodeVideo(liteav::TXLiteAVEncodedData & videoData) {
	    if (videoData.processedData && encrypt_key_.size()) {
    	    XORData(videoData);

    	    return true;
	    }

	    return false;
    }

    bool willDecodeVideo(liteav::TXLiteAVEncodedData & videoData) {
	    if (videoData.processedData && encrypt_key_.size()) {
    	    XORData(videoData);

    	    return true;
	    }

	    return false;
    }

    bool didEncodeAudio(liteav::TXLiteAVEncodedData & audioData) {
	    if (audioData.processedData && encrypt_key_.size()) {
    	    XORData(audioData);

    	    return true;
	    }

	    return false;
    }

    bool willDecodeAudio(liteav::TXLiteAVEncodedData & audioData) {
	    if (audioData.processedData && encrypt_key_.size()) {
    	    XORData(audioData);

    	    return true;
	    }

	    return false;
    }

    void XORData(liteav::TXLiteAVEncodedData & encodedData) {
	    auto srcData = encodedData.originData->cdata();
	    auto keySize = encrypt_key_.size();
	    auto dataSize = encodedData.originData->size();
	    encodedData.processedData->SetSize(dataSize);
	    auto dstData = encodedData.processedData->data();
	    for (int i=0; i<dataSize; ++i) {
    	    dstData[i] = srcData[i] ^ encrypt_key_[i % keySize];
	    }
    }

    std::string encrypt_key_;
};


static TRTCCustomerCrypt *s_customerCrypt = nil;


@interface TRTCCustomerCrypt ()
{
    TRTCCustomerEncryptor _encyptor;
}
@end

@implementation TRTCCustomerCrypt

+ (instancetype)sharedInstance {
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
	    s_customerCrypt = [[TRTCCustomerCrypt alloc] initPrivate];
    });
    return s_customerCrypt;
}

- (instancetype)initPrivate {
    self = [super init];
    if (nil != self) {
    }
    return self;
}

- (void *)getEncodedDataProcessingListener {
    if (self.encryptKey == nil || self.encryptKey.length == 0) return nullptr;

    _encyptor.encrypt_key_ = [[self.encryptKey md5] UTF8String];

    return &_encyptor;
}

@end
#endif
