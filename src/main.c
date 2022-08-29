#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include <avr/pgmspace.h>

typedef unsigned char u8;
#define b 1

//#define orgin
#define opt
#define optopt

extern void encrypt(const u8 *in, u8 *out, const u8 *key);

extern void encrypt_opt(const u8 *in, u8 *out, const u8 *key);

extern void encrypt_opt_opt(const u8 *in, u8 *out, const u8 *key);


void addmul(u8* key) {
  for (int i = 0; i <6 ; i++) {
	  key[i*16] = 0x00 ^ (i+1) ^ b;
	  key[(i*16)+4] = 0x10 ^ (i+1) ^ b;
	  key[(i*16)+8] = 0x20 ^ (i+1) ^ b;
	  key[(i*16)+12] = 0x30 ^ (i+1) ^b;
	  
  }
}


void addmul_opt(u8* key){
	 for (int i = 0; i <6 ; i++) {
		 key[i*4] = 0x00 ^ (i+1) ^ b;
		 key[i*4+1] = 0x10 ^ (i+1) ^ b;
		 key[i*4+2] = 0x20 ^ (i+1) ^ b;
		 key[i*4+3] = 0x30 ^ (i+1) ^b;
		 
	 }
}

int main(void)
{
  //uint8 pt[16], ct[16], k[16], out[16];
  //uint8 i, j;
	//u8 pt[16] = {0xdd, 0x6a, 0xb2, 0xf3,0x11, 0x22, 0x66, 0x77, 0x81, 0x19, 0xC6, 0xA1, 0xFF, 0xEA, 0xB4, 0x1C };
	u8 pt[16] = {0x00, };
	u8 out[16] = {0, };
	//u8 k[16] = {0x00, 0x00, 0x00, 0x00, 0x10, 0x00, 0x00, 0x00, 0x20, 0x00, 0x00, 0x00, 0x30, 0x00, 0x00, 0x00};
	u8 key[16*6] = {0x00,};
	u8 key_opt[4*6] = {0,};
		
	//addmul(key);
	//encrypt_opt(pt,out, key);
	
	addmul_opt(key_opt);
	encrypt_opt_opt(pt, out, key_opt);
	
/*	
#ifdef orgin
	encrypt(pt,out,k);
	
#elif defined opt 
	encrypt_opt(pt,out,key);

else

	encrypt_opt_opt(pt,out,key);
#endif
	
	*/
  return 0;
}
