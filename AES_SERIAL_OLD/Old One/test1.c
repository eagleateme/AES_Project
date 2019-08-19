#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
void Generate_Countered_Key(char* temp_key_str)
{
	for(int i=0 ; i < 16 ; i++)
	{
		key_str[i] = temp_key_str[i];
	}

	while(counter <= 4)
	{
		
		counter++;
	}

	key_str[16*4] = '\0';
}



int main()
{	
	char* str =(char*)calloc(17,sizeof(char));
	//scanf("%s",str);
	uint8_t counter_1 = 0x01;

	for(int i = 0 ; i < 16; i = i+2)
	{
		str[i] = 0xa;
		str[i+1] = i/2;
	}
	str[16] = '\0';

	for(int i = 0 ; i < 16 ; i++)
	{
		printf(" %2X ",str[i]);
	}

	for(int i = 15 ; i >= 0 ; i--)
	{
		int temp = str[i]+counter;

			if(temp >= 16)
			{
				str[i] = temp%16;
				counter = temp/16;
			}
			else{
				str[i] = str[i]+counter;
				counter = 0x00;

			}
	}
	for(int i = 0 ; i < 16 ; i++)
	{
		printf(" %2X ",str[i]);
	}


}