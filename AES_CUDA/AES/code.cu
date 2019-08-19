#include "AES.h"
#include <string.h>
#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <stdint.h>

u_char s_box[] = {0x63, 0x7c, 0x77, 0x7b, 0xf2, 0x6b, 0x6f, 0xc5, 0x30, 0x01, 0x67, 0x2b, 0xfe, 0xd7, 0xab, 0x76,
  0xca, 0x82, 0xc9, 0x7d, 0xfa, 0x59, 0x47, 0xf0, 0xad, 0xd4, 0xa2, 0xaf, 0x9c, 0xa4, 0x72, 0xc0,
  0xb7, 0xfd, 0x93, 0x26, 0x36, 0x3f, 0xf7, 0xcc, 0x34, 0xa5, 0xe5, 0xf1, 0x71, 0xd8, 0x31, 0x15,
  0x04, 0xc7, 0x23, 0xc3, 0x18, 0x96, 0x05, 0x9a, 0x07, 0x12, 0x80, 0xe2, 0xeb, 0x27, 0xb2, 0x75,
  0x09, 0x83, 0x2c, 0x1a, 0x1b, 0x6e, 0x5a, 0xa0, 0x52, 0x3b, 0xd6, 0xb3, 0x29, 0xe3, 0x2f, 0x84,
  0x53, 0xd1, 0x00, 0xed, 0x20, 0xfc, 0xb1, 0x5b, 0x6a, 0xcb, 0xbe, 0x39, 0x4a, 0x4c, 0x58, 0xcf,
  0xd0, 0xef, 0xaa, 0xfb, 0x43, 0x4d, 0x33, 0x85, 0x45, 0xf9, 0x02, 0x7f, 0x50, 0x3c, 0x9f, 0xa8,
  0x51, 0xa3, 0x40, 0x8f, 0x92, 0x9d, 0x38, 0xf5, 0xbc, 0xb6, 0xda, 0x21, 0x10, 0xff, 0xf3, 0xd2,
  0xcd, 0x0c, 0x13, 0xec, 0x5f, 0x97, 0x44, 0x17, 0xc4, 0xa7, 0x7e, 0x3d, 0x64, 0x5d, 0x19, 0x73,
  0x60, 0x81, 0x4f, 0xdc, 0x22, 0x2a, 0x90, 0x88, 0x46, 0xee, 0xb8, 0x14, 0xde, 0x5e, 0x0b, 0xdb,
  0xe0, 0x32, 0x3a, 0x0a, 0x49, 0x06, 0x24, 0x5c, 0xc2, 0xd3, 0xac, 0x62, 0x91, 0x95, 0xe4, 0x79,
  0xe7, 0xc8, 0x37, 0x6d, 0x8d, 0xd5, 0x4e, 0xa9, 0x6c, 0x56, 0xf4, 0xea, 0x65, 0x7a, 0xae, 0x08,
  0xba, 0x78, 0x25, 0x2e, 0x1c, 0xa6, 0xb4, 0xc6, 0xe8, 0xdd, 0x74, 0x1f, 0x4b, 0xbd, 0x8b, 0x8a,
  0x70, 0x3e, 0xb5, 0x66, 0x48, 0x03, 0xf6, 0x0e, 0x61, 0x35, 0x57, 0xb9, 0x86, 0xc1, 0x1d, 0x9e,
  0xe1, 0xf8, 0x98, 0x11, 0x69, 0xd9, 0x8e, 0x94, 0x9b, 0x1e, 0x87, 0xe9, 0xce, 0x55, 0x28, 0xdf,
  0x8c, 0xa1, 0x89, 0x0d, 0xbf, 0xe6, 0x42, 0x68, 0x41, 0x99, 0x2d, 0x0f, 0xb0, 0x54, 0xbb, 0x16
};
u_char Rcon[11] = {0x8d, 0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80, 0x1b, 0x36 };

void Generate_Nonce_Text(u_char *nonceArr, int blockSize, int numBlocks)
{
	//for each block
	for(int count = 0 ; count < numBlocks ; count++)
	{
		u_char counter_1 = 0x01;

		//for each byte per block
		for(int i = blockSize-1; i >= 0 ; i--)
		{

			int temp = nonceArr[blockSize*count+i]+counter_1;

				if(temp == 256) // > 256
				{
					nonceArr[(blockSize*(count+1))+i] = 0x00;// temp%256
					counter_1 = 0x01;//counter = temp/256;
				}
				else
				{
					nonceArr[(blockSize*(count+1))+i] = temp;// nonceArr[(blockSize*(count))+i]+counter_1;
					counter_1 = 0x00;
				}
		}

	}

	//nonceArr[blockSize*numBlocks]= '\0';
}

//Multiplication in GF(2^8)(source: Wiki)
__device__ u_char gmul(u_char a, u_char b){
	u_char p = 0; /* the product of the multiplication */
	while (a && b) {
	        if (b & 1) /* if b is odd, then add the corresponding a to p (final product = sum of all a's corresponding to odd b's) */
	            p ^= a; /* since we're in GF(2^m), addition is an XOR */

	        if (a & 0x80) /* GF modulo: if a >= 128, then it will overflow when shifted left, so reduce */
	            a = (a << 1) ^ 0x11b; /* XOR with the primitive polynomial x^8 + x^4 + x^3 + x + 1 (0b1_0001_1011) – you can change it but it must be irreducible */
	        else
	            a <<= 1; /* equivalent to a*2 */
	        b >>= 1; /* equivalent to b // 2 */
			}
	return p;}

__device__ void SubBytes(u_char **state_t,u_char* d_sbox){
	for(int i = 0 ; i < 4; i++)
		for(int j = 0 ; j < 4 ; j++)
			state_t[i][j] = d_sbox[state_t[i][j]];
}

__device__ void ShiftRows(u_char **state_t){
	for(int i = 0 ; i < 4 ; i++)
	{
		for(int j = i ; j > 0  ; j--)
		{
			u_char temp = state_t[i][0];
			for(int j = 1 ;j < 4; j++)
			{
				state_t[i][j-1] = state_t[i][j];
			}

			state_t[i][3] = temp;
		}
	}
}

void KeyExpansionFunc(Key *Expanded_Key_arr, Key k_init){
	Word temp;
	int round_no = 1;

	for(int i = 0 ; i < 4 ; i++)
	{
		Expanded_Key_arr[0].word[i] = k_init.word[i];
	}

	for(int m = 1;  m < 11 ; m++)
	{
		for(int i = 0; i < 4 ; i++)
		{
			if(i != 0)
				temp = Expanded_Key_arr[m].word[i-1];

			if(i == 0)
			{

				temp = Expanded_Key_arr[m-1].word[3];

				//Left Circular Shift (ByteWise)
				u_char temp_byte = temp.byte[0];
				for(int j = 1 ; j < 4 ; j++)
				{
					temp.byte[j-1] = temp.byte[j];
				}
				temp.byte[3] = temp_byte;
				//Getting S box Value
				for(int j = 0 ;  j < 4; j++)
				{
					temp.byte[j] = s_box[temp.byte[j]];
				}
				temp.byte[0] = temp.byte[0]^Rcon[round_no];
				round_no++;
			}

			for(int j = 0 ;  j < 4; j++)
			{
					Expanded_Key_arr[m].word[i].byte[j] = (Expanded_Key_arr[m-1].word[i].byte[j])^temp.byte[j];
			}
		}
	}
}

void PrintKey(int i, Key *Expanded_Key_arr){

		for(int j =0 ; j < 4; j++)
		{
			for(int k =0 ; k < 4; k++)
			{
				printf(" %2X ",Expanded_Key_arr[i].word[j].byte[k]);
			}
			printf("\n");
		}
		printf("\n\n\n");
}

__device__ void MixColumns(u_char **state_t,u_char* d_mixMat){
	u_char **temp_state = (u_char **)malloc(sizeof(u_char *)*4);
	for(int i = 0; i < 4; i++)
		 temp_state[i] = (u_char *)malloc(sizeof(u_char)*4);

	for(int i = 0 ; i < 4 ; i++)
	{
		for(int j = 0 ; j < 4; j++)
		{
			int sum = 0 ;
			for(int k = 0 ; k < 4 ; k++)
			{
				sum = sum^gmul(d_mixMat[i*4+k],state_t[k][j]);
			}
			temp_state[i][j] = sum;
		}
	}
	for(int i = 0 ; i < 4 ; i++)
	{
		for(int j = 0 ; j < 4; j++)
		{
			state_t[i][j] = temp_state[i][j];
		}
	}
}


Key Copy_key_str(char* str)
{
	Key temp_arr;

	int i = 0;

		for(int j = 0 ;  j < 4; j++)
		{
			for(int k = 0 ;  k < 4; k++)
			{
				temp_arr.word[j].byte[k] = str[i];
				i++;
			}
		}

		return temp_arr;
}

__device__ void AddRoundKey(u_char* mod_arr, u_char **state_t, int round){

	for(int i = 0 ; i < 4 ; i++)
	{
		for(int j = 0 ; j < 4; j++)
		{
			state_t[i][j] = state_t[i][j]^mod_arr[round*16+j*4+i];

		}
	}
}

//blockSize,nonceArr,mod_arr, 
__global__ void func(u_char *nonceArr, u_char *mod_arr, u_char *sbox, u_char *mixmat, u_char* input_arr,u_char *ciphertext,int blockSize) {
	int id  = threadIdx.x;

	u_char **state_t = (u_char **)malloc(sizeof(u_char *)*4);
	for(int i = 0; i < 4; i++)
 		state_t[i] = (u_char *) malloc(sizeof(u_char)*4);

 	/*
		//Copy__state_str(blockSize);//Copy To The Temp for Multiplication
		for(int j = 0 ; j < blockSize ; j++){
			state_t[j%4][j/4] = nonceArr[blockSize*id+j];
			//nonceArr[id*blockSize+ j] = state_t[j%4][j/4] ^ input_arr[id*blockSize + j];
		}
		AddRoundKey(Expanded_Key_arr,state_t,0);
		for(int i = 1; i <= 10 ; i++)
		{
			SubBytes(state_t);
			ShiftRows(state_t);

			if(i != 10)
			{
			 	MixColumns(state_t);
			}
			AddRoundKey(Expanded_Key_arr,state_t,i);
		}
		//Copy_Plain(blockSize);

		for(int j = 0 ; j < blockSize ; j++){
			nonceArr[id*blockSize+ j] = state_t[j%4][j/4] ^ input_arr[id*blockSize + j];
		}
	*/

	for(int j = 0 ; j < blockSize ; j++){
    	state_t[j%4][j/4] = nonceArr[blockSize*id+j];
	}
	AddRoundKey(mod_arr,state_t,0);
	for(int i = 1; i <= 10 ; i++)
	{
		SubBytes(state_t,sbox);
		ShiftRows(state_t);

		if(i != 10)
		{
			MixColumns(state_t,mixmat);
		}
		AddRoundKey(mod_arr,state_t,i);
	}

	for(int j = 0; j < blockSize; j++){
		ciphertext[blockSize*id + j] =  state_t[j%4][j/4] ^ input_arr[id*blockSize + j];;
	}

	//printf("%d %2X\n", id, sbox[id]);
}


int main() {

	u_char *d_sbox,*d_nonceArr,*d_mod_arr,*d_mixMat, *d_ciphertext,*d_input_arr;
	int blockSize = 16, numBlocks = 1500;
	u_char Mix_Mat[16] = {0x02,0x03,0x01,0x01,0x01,0x02,0x03,0x01,0x01,0x01,0x02,0x03,0x03,0x01,0x01,0x02};
	char* key_str =(char*) calloc(blockSize+1,sizeof(char));//Key
	u_char *nonceArr = (u_char*)malloc(sizeof(u_char)*(blockSize*numBlocks));
	char* nonce = (char*)calloc(blockSize+1,sizeof(char));
	u_char *ciphertext = (u_char*)malloc(sizeof(u_char)*(blockSize*numBlocks));
    u_char* input_arr =(u_char *) calloc(blockSize*numBlocks,sizeof(u_char));

	Key Expanded_Key_arr[11];


	FILE* f1 = fopen("plain_text.txt","r");
	fread(input_arr,sizeof(u_char),numBlocks*blockSize,f1);

	strcpy(nonce,"Two One Nine Two");

	for(int i = 0 ; i < blockSize; i++)
	{
		nonceArr[i] = nonce[i];
	}
	Generate_Nonce_Text(nonceArr,blockSize,numBlocks);
	strcpy(key_str,"Thats my Kung Fu");//Hardcoding Key
	Key temp_keys = Copy_key_str(key_str);
	KeyExpansionFunc(Expanded_Key_arr, temp_keys);
	u_char* mod_arr  = (u_char*)calloc(11*4*4,sizeof(u_char));
	for(int r = 0 ; r < 11 ; r++)
	{
		for(int i = 0 ; i < 4 ; i++)
		{
		 	for(int j = 0 ; j < 4; j++)
		 	{
		 		mod_arr[r*16+j*4+i] = Expanded_Key_arr[r].word[j].byte[i];

		 	}
		}
	}
	for(int i = 0; i < 11; i++) {
		PrintKey(i,Expanded_Key_arr);
	} 

	//CORRECT TILL HERE

	cudaMalloc((void **)&d_input_arr, (blockSize*numBlocks)*sizeof(u_char));
	cudaMemcpy(d_input_arr, input_arr, (blockSize*numBlocks) * sizeof(u_char), cudaMemcpyHostToDevice);
	cudaMalloc((void **)&d_nonceArr, (blockSize*numBlocks)*sizeof(u_char));
	cudaMemcpy(d_nonceArr, nonceArr, (blockSize*numBlocks) * sizeof(u_char), cudaMemcpyHostToDevice);
	cudaMalloc((void **)&d_ciphertext, (blockSize*numBlocks)*sizeof(u_char));
	cudaMemcpy(d_ciphertext, ciphertext, (blockSize*numBlocks) * sizeof(u_char), cudaMemcpyHostToDevice);
	cudaMalloc((void **)&d_mod_arr, 11*4*4*sizeof(u_char));
	cudaMemcpy(d_mod_arr, mod_arr, 11*4*4*sizeof(u_char), cudaMemcpyHostToDevice);
	cudaMalloc((void **)&d_sbox, 256*sizeof(u_char));
	cudaMemcpy(d_sbox, s_box, 256 * sizeof(u_char), cudaMemcpyHostToDevice);
	cudaMalloc((void **)&d_mixMat, 16*sizeof(u_char));
	cudaMemcpy(d_mixMat, Mix_Mat, 16 * sizeof(u_char), cudaMemcpyHostToDevice);
	func<<<1, 11>>>(d_nonceArr,d_mod_arr,d_sbox,d_mixMat,d_input_arr,d_ciphertext,blockSize);
	cudaMemcpy(ciphertext, d_ciphertext, (blockSize*numBlocks) * sizeof(u_char), cudaMemcpyDeviceToHost);
	for(int i = 0 ; i < blockSize*numBlocks ; i++)
		{
			if(i%16 == 0)
				printf("\n");

			printf(" %.2X ",ciphertext[i]);
		}
	cudaFree(d_sbox);
}