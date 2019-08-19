#include "AES.h"
#include <string.h>
#include "func_const.h"


int main()
{
	char* str = (char*)calloc(17,sizeof(char));
	char* key_str = (char*)calloc(17,sizeof(char));

	printf("\nType the String:");
	scanf(" %[^\n]", str);
	Copy__state_str(str);//Copy To The Temp for Multiplication

	printf("\nType the Key String:");
	scanf(" %[^\n]",key_str);
	Key temp_keys = Copy_key_str(key_str);
	KeyExpansionFunc(temp_keys);
	AddRoundKey(0);
	for(int i = 1; i <= 10 ; i++)
	{
		SubBytes();
		ShiftRows();
				
		if(i != 10)
		{
		 	MixColumns();
		}	
		AddRoundKey(i);
		printf("\nRound : %d\n",i);
		PrintMat();
	}
	// //Code Checked for https://kavaliro.com/wp-content/uploads/2014/03/AES.pdf example
	// //The Last round in Text Book is Wrong
	return 0;
}


