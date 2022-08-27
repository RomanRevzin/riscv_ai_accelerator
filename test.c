#define LEDS_BASE_ADDR 0x010
#define LEDS LEDS_BASE_ADDR 
#define SEVSEG (LEDS_BASE_ADDR +4)

#define ACCEL_BASE 0x020
#define ACCEL_CTRL ACCEL_BASE 
#define ACCEL_PERF_COUNTER (ACCEL_BASE + 0x4)

#define ACCEL_A (ACCEL_BASE + 0x8)
#define ACCEL_B (ACCEL_BASE + 0xc)
#define ACCEL_C (ACCEL_BASE + 0x10)
#define ACCEL_D (ACCEL_BASE + 0x14)
#define ACCEL_E (ACCEL_BASE + 0x18)
#define ACCEL_F (ACCEL_BASE + 0x1c)
#define ACCEL_G (ACCEL_BASE + 0x20)
#define ACCEL_H (ACCEL_BASE + 0x24)

#define PRINT(i, j) *((int *)(i)) = (j)
#define STOP while(1)


int main(){
	int* accel_ctrl_ptr = (int *)ACCEL_CTRL;
	int* accel_perf_ctr = (int *)ACCEL_PERF_COUNTER;
	
	int* accel_data_a_ptr = (int *)ACCEL_A; //image row 1
	int* accel_data_b_ptr = (int *)ACCEL_B; //image row 2
	int* accel_data_c_ptr = (int *)ACCEL_C; //image row 3
	int* accel_data_d_ptr = (int *)ACCEL_D; //image row 4
	int* accel_data_e_ptr = (int *)ACCEL_E; //mask row 1
	int* accel_data_f_ptr = (int *)ACCEL_F; //mask row 2
	int* accel_data_g_ptr = (int *)ACCEL_G; //mask row 3
	int* accel_data_h_ptr = (int *)ACCEL_H; //result

	*accel_data_a_ptr = 0x010101ff;
	*accel_data_b_ptr = 0x01020201;
	*accel_data_c_ptr = 0x01020201;
	*accel_data_d_ptr = 0x01010101;	
	*accel_data_e_ptr = 0x01010100;
	*accel_data_f_ptr = 0x01010100;
	*accel_data_g_ptr = 0x01010100;
	*accel_ctrl_ptr   = 0x00000100;
	
	PRINT(SEVSEG, *accel_data_h_ptr);
	PRINT(LEDS, *accel_perf_ctr);
	STOP;
}
