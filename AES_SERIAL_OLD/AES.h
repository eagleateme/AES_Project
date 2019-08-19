#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

//uint8_t makes sure that your basic unit is a byte of 8bits



//Defining a Word Data_Structure
typedef struct node
{
  uint8_t byte[4];
}Word;

typedef struct node1
{
	Word word[4];
}Key;


