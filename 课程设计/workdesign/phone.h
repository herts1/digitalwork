#ifndef PHONE_H
#define PHONE_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_CUSTOMERS   100  //最大用户数 
#define MAX_CALLS       500  //最多通化 
#define PHONE_LEN       12   //11位手机号 
#define ID_LEN          19   //18位身份证 
#define NAME_LEN        32   //汉字姓名 

//哈希表容量： 
#define PHONE_TABLE_SIZE  61
#define NAME_TABLE_SIZE   61



/* 哈希函数类型 */
#define HASH_DIV   0    //除留余数法   h(key) = key mod m
#define HASH_FOLD  1    //折叠法  

/* 冲突处理方法 */
#define PROBE_LINEAR   0   //线性探测开放寻址  
#define PROBE_CHAIN    1   //链地址法  


//用户信息： 
typedef struct {
    char name[NAME_LEN];
    char id[ID_LEN];
    char phone[PHONE_LEN];
    int  call_count;   //通话次数
} Customer;  

//开放寻址哈希表槽：
typedef struct {
    int  valid;         //0=空, 1=已占用, 2=已删除 
    int  cust_idx;      //指向customers数组下标  
 } OASlot;


//链地址哈希表节点：
 typedef struct ChainNode {
     int  cust_idx;
     struct ChainNode *next;
 } ChainNode;

/* ? 只声明，不定义 */
extern Customer customers[MAX_CUSTOMERS];
extern int      cust_cnt;

extern char call_from[MAX_CALLS][PHONE_LEN];
extern char call_to  [MAX_CALLS][PHONE_LEN];
extern int  call_cnt;


extern OASlot   phone_oa[PHONE_TABLE_SIZE];   /* 手机号 开放寻址 */
extern ChainNode *phone_ch[PHONE_TABLE_SIZE]; /* 手机号 链地址   */
extern OASlot   name_oa [NAME_TABLE_SIZE];    /* 姓名   开放寻址 */
extern ChainNode *name_ch[NAME_TABLE_SIZE];   /* 姓名   链地址   */

/*------------------------文件读取--------------------------*/
int load_customers(const char *filename);
 
int load_calls(const char *filename);



/*--------------------------函数----------------------------*/
static unsigned long phone_to_ul(const char *phone);  //将11位手机号转为无符号长整数
static int hash_div_phone(const char *phone, int size);  //除留余数-电话号码 
static int hash_div_name(const char *name, int size);    //除留余数-名字
 
 
static int hash_fold_phone(const char *phone, int size);  //折叠法-电话号码 
static int hash_fold_name(const char *name, int size);    //折叠法-名字


//统一： 
static int hash_phone(const char *phone, int size, int htype);
static int hash_name(const char *name, int size, int htype);


void count_calls(void);   //统计通话次数

/*---------------------开放寻址哈希表-----------------------*/

 void oa_init(OASlot *table, int size);
 
int oa_insert_phone(OASlot *table, int size, int cust_idx, int htype);  //插入，返回探测次数

int oa_insert_name(OASlot *table, int size, int cust_idx, int htype);


int oa_find_phone(OASlot *table, int size, const char *phone, int htype);  //按手机号查找 

int oa_find_name(OASlot *table, int size, const char *name, int htype);  //按姓名查找


/*---------------------链地址哈希表-----------------------*/
void ch_init(ChainNode **table, int size);

void ch_free(ChainNode **table, int size);

int ch_insert_phone(ChainNode **table, int size, int cust_idx, int htype);

int ch_insert_name(ChainNode **table, int size, int cust_idx, int htype);

int ch_find_phone(ChainNode **table, int size, const char *phone, int htype);

int ch_find_name(ChainNode **table, int size, const char *name, int htype);

/*---------------------构建所有哈希表-----------------------*/

typedef struct {
    int  collisions;   //冲突次数 
    long total_probe;  //总探测次数（用于计算平均查找长度）
    int  inserted;     //成功插入数 
} HashStats;


HashStats build_phone_oa(OASlot *table, int size, int htype);

HashStats build_name_oa(OASlot *table, int size, int htype);

HashStats build_phone_ch(ChainNode **table, int size, int htype);

HashStats build_name_ch(ChainNode **table, int size, int htype);

/*---------------------功能函数-----------------------*/

//功能2：查找聊天狂人
void find_maniac(void);

//功能3：按姓名查找
void find_by_name(const char *name);

//功能4：冲突率比较
void compare_hash_functions(void);

//功能5：平均查找长度比较
void compare_collision_methods(void);


/*-------------------按手机号查找（菜单辅助）---------------------*/


void find_by_phone(const char *phone);


/*-------------------主菜单---------------------*/

void print_menu(void);


#endif
