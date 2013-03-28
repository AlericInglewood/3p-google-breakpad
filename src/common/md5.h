// Copyright 2007 Google Inc. All Rights Reserved.
// Author: liuli@google.com (Liu Li)
#ifndef COMMON_MD5_H__
#define COMMON_MD5_H__

namespace google_breakpad {

struct MD5Context {
  unsigned int buf[4];
  unsigned int bits[2];
  unsigned char in[64];
};

void MD5Init(struct MD5Context *ctx);

void MD5Update(struct MD5Context *ctx, unsigned char const *buf, unsigned len);

void MD5Final(unsigned char digest[16], struct MD5Context *ctx);

}  // namespace google_breakpad

#endif  // COMMON_MD5_H__
