void PrintKey(int i){
	
		for(int j =0 ; j < 4; j++)
		{
			for(int k =0 ; k < 4; k++)
			{
				printf(" %2X ",Expanded_Key_arr[i].word[j].byte[k]);
			}
			printf("\n");
		}
		printf("\n\n\n");}

void PrintMat(){

	for(int i = 0 ; i < 4; i++)
	{
		for(int j = 0 ;  j < 4 ; j++)
		{
		
			printf(" %02X ", state_t[i][j]);
		}

		printf("\n");
	}
	printf("\n\n");}
void KeyExpansionFunc(Key k_init){
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
				uint8_t temp_byte = temp.byte[0];
				for(int j = 1 ; j < 4 ; j++)
				{
					temp.byte[j-1] = temp.byte[j];
				}
				temp.byte[3] = temp_byte;
				//Getting S box Value
				for(int j = 0 ;  j < 4; j++)
				{
					temp.byte[j] = sbox[temp.byte[j]];
				}
				temp.byte[0] = temp.byte[0]^Rcon[round_no];
				round_no++;
			}

			for(int j = 0 ;  j < 4; j++)
			{
					Expanded_Key_arr[m].word[i].byte[j] = (Expanded_Key_arr[m-1].word[i].byte[j])^temp.byte[j];
			}
		}
	}}
void SubBytes(){
	for(int i = 0 ; i < 4; i++)
		for(int j = 0 ; j < 4 ; j++)
			state_t[i][j] = sbox[state_t[i][j]];}
void ShiftOnce(int i){
	uint8_t temp = state_t[i][0];

	for(int j = 1 ;j < 4; j++)
	{
		state_t[i][j-1] = state_t[i][j];
	}

	state_t[i][3] = temp;}
void ShiftRows(){
	for(int i = 0 ; i < 4 ; i++)
	{
		for(int j = i ; j > 0  ; j--)
		{
			ShiftOnce(i);
		}
	}}

	void Copy_State(){
	for(int i = 0 ; i < 4 ; i++)
	{
		for(int j = 0 ; j < 4; j++)
		{
			state_t[i][j] = temp_state[i][j];
		}
	}}
//Multiplication in GF(2^8)(source: Wiki)
uint8_t gmul(uint8_t a, uint8_t b){
	uint8_t p = 0; /* the product of the multiplication */
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
void MixColumns(){
	for(int i = 0 ; i < 4 ; i++)
	{
		for(int j = 0 ; j < 4; j++)
		{
			int sum = 0 ;
			for(int k = 0 ; k < 4 ; k++)
			{
				sum = sum^gmul(Mix_Mat[i][k],state_t[k][j]);
			}
			temp_state[i][j] = sum;
		}
	}
	Copy_State();
}
void AddRoundKey(int round){

	for(int i = 0 ; i < 4 ; i++)
	{
		for(int j = 0 ; j < 4; j++)
		{
			state_t[i][j] = state_t[i][j]^Expanded_Key_arr[round].word[j].byte[i];

		}
	}}

void Copy__state_str(char* str)
{
	int i = 0;

		for(int j = 0 ;  j < 4; j++)
		{
			for(int k = 0 ;  k < 4; k++)
			{
				state_t[k][j] = str[i];
				i++;
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
