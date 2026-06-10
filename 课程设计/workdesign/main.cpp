#include <iostream>
#include "phone.h"

#include<stdio.h>
#include<stdlib.h>



/* run this program using the console pauser or add your own getch, system("pause") or input loop */


int main( ) {
	 /* ---- 加载数据 ---- */
	    printf("正在加载数据...\n");
	    if (load_customers("customers.txt") < 0) return 1;
	    if (load_calls("calls.txt")         < 0) return 1;
	    count_calls();
	
	    /* ---- 构建默认哈希表（链地址 + 除留余数，用于实时查询）---- */
	    ch_init(phone_ch, PHONE_TABLE_SIZE);
	    ch_init(name_ch,  NAME_TABLE_SIZE);
	    for (int i = 0; i < cust_cnt; i++) {
	        ch_insert_phone(phone_ch, PHONE_TABLE_SIZE, i, HASH_DIV);
	        ch_insert_name (name_ch,  NAME_TABLE_SIZE,  i, HASH_DIV);
	    }
	
	    /* ---- 菜单循环 ---- */
	    int choice;
	    char buf[64];
	    while (1) {
	        printf("\n");
	        print_menu();
	        if (scanf("%d", &choice) != 1) { while (getchar() != '\n'); continue; }
	        while (getchar() != '\n');   /* 清空缓冲区 */
	
	        switch (choice) {
	        case 1:
	            find_maniac();
	            break;
	        case 2:
	            printf("请输入姓名: ");
	            fgets(buf, sizeof(buf), stdin);
	            buf[strcspn(buf, "\r\n")] = '\0';
	            find_by_name(buf);
	            break;
	        case 3:
	            printf("请输入手机号: ");
	            fgets(buf, sizeof(buf), stdin);
	            buf[strcspn(buf, "\r\n")] = '\0';
	            find_by_phone(buf);
	            break;
	        case 4:
	            compare_hash_functions();
	            break;
	        case 5:
	            compare_collision_methods();
	            break;
	        case 0:
	            printf("已退出系统。\n");
	            ch_free(phone_ch, PHONE_TABLE_SIZE);
	            ch_free(name_ch,  NAME_TABLE_SIZE);
	            return 0;
	        default:
	            printf("无效输入，请重试。\n");
	        }
	    }
	    return 0;
}
